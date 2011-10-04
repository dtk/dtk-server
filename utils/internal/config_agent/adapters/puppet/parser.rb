require 'rubygems'
require 'pp'
require 'puppet'

module XYZ
  class Puppet
    class ParseStructure < Hash
    end

    class ComponentPS < ParseStructure
      #TODO: use opts to specify what to parse and what to ignore
      def initialize(ast_item,opts={})
        type =
          if puppet_type?(ast_item,:hostclass)
            "puppet_class"
          elsif puppet_type?(ast_item,:definition)
            "puppet_definition"
          else
            raise Error.new("unexpected type for ast_item")
          end
        self[:type] = type
        self[:name] = ast_item.name
        self[:attributes] = (ast_item.context[:arguments]||[]).map{|arg|AttributePS.create(arg,opts)}
        children = parse_children(ast_item,opts)
        self[:children] = children if children and not children.empty?
        super
      end
     private
      def parse_children(ast_item,opts)
        return nil unless code = ast_item.context[:code]
        ret = Array.new
        (code.children||[]).each do |child_ast_item|
          ret += parse_child(child_ast_item,opts)
        end
        ret
      end 

      def parse_child(child_ast_item,opts)
        ret = Array.new
        if fn = process_fn(child_ast_item,opts)
          ret += Array(send(fn,child_ast_item,opts))
        end
        ret
      end

      def process_fn(ast_item,opts) 
        #TODO: make what is ignored and treated fn of opts
        types_to_ignore = [:var_def,:relationship]
        types_to_process = [:collection,:resource,:if_statement,:case_statement,:function]
        return nil if puppet_type?(ast_item,types_to_ignore)
        if type = puppet_type?(ast_item,types_to_process)
          "parse__#{type}".to_sym
        else
          raise Error.new("unexpected ast type (#{ast_item.class.to_s})")
        end
      end

      def parse__collection(ast_item,opts)
        if ast_item.form == :exported
          ExportedCollectionPS.create(ast_item,opts)
        end
      end

      def parse__resource(ast_item,opts)
        #TODO: case on opts what is returned; here we are casing on just external resources
        if ast_item.exported
          ExportedResourcePS.create(ast_item,opts)
        end
      end

      def parse__function(ast_fn,opts)
        case ast_fn.name
          when "require" then RequireStatementPS.create(ast_fn,opts) 
          when "include" then IncludeStatementPS.create(ast_fn,opts) 
        else
          nil #ignore all others
        end
      end
      def parse__if_statement(ast_item,opts)
        #TODO: this flattens the "if call" and returns both sides; whether this shoudl be done may be dependent on ops
        ret = Array.new
        IfStatementPS.flat_statement_iter(ast_item,opts) do |child_ast_item|
          ret += parse_child(child_ast_item,opts)
        end
        ret
      end

      def parse__case_statement(ast_item,opts)
        #TODO: this flattens the "if call" and returns both sides; whether this shoudl be done may be dependent on ops
        ret = Array.new
        CaseStatementPS.flat_statement_iter(ast_item,opts) do |child_ast_item|
          ret += parse_child(child_ast_item,opts)
        end
        ret
      end
    end

    class ExportedResourcePS < ParseStructure
      def initialize(ast_resource,opts={})
        self[:type] = ast_resource.type
        self[:paramters] =  resource_parameters(ast_resource,opts)
        super
      end
     private
      def resource_parameters(ast_resource,opts)
        children = ast_resource.instances.children
        unless children.size == 1
          raise Error.new("unexpected to have number of resource children neq to 1")
        end
        params = children.first.parameters.children
        params.map do |ast_rsc_param|
          if ast_rsc_param.kind_of?(::Puppet::Parser::AST::ResourceParam)
            ResourceParamPS.create(ast_rsc_param,opts)
          else
            raise Error.new("Unexpected child of resource (#{ast_rsc_param.class.to_s})")
          end
        end
      end
    end

    class ExportedCollectionPS < ParseStructure
      def initialize(ast_coll,opts={})
        self[:type] = ast_coll.type
        self[:query] =  ast_coll.query
        super
      end
    end

    module ConditionalStatementsMixin
      def flat_statement_iter(ast_item,opts={},&block)
        next_level_statements(ast_item).each do |child_ast_item|
          just_pass_thru = puppet_type?(child_ast_item,[:resource,:function,:collection])
          if just_pass_thru
            block.call(child_ast_item)
          elsif puppet_type?(child_ast_item,:if_statement)
            IfStatementPS.flat_statement_iter(child_ast_item,opts,&block)
          elsif puppet_type?(child_ast_item,:case_statement)
            CaseStatementPS.flat_statement_iter(child_ast_item,opts,&block)
          else
            raise Error.new("unexpected statement in 'if statement' body having ast class (#{child_ast_item.class.to_s})")
          end
        end
      end      
    end

    class IfStatementPS < ParseStructure
      extend ConditionalStatementsMixin
      def self.next_level_statements(ast_if_stmt)
        ast_if_stmt.statements.children
      end
    end

    class CaseStatementPS < ParseStructure
      extend ConditionalStatementsMixin
      def self.next_level_statements(ast_case_stmt)
        ast_case_stmt.options.children.map{|x|x.statements.children}.flatten(1)
      end
    end

    class ResourceParamPS < ParseStructure
      def initialize(ast_rsc_param,opts={})
        self[:name] = ast_rsc_param.param
        #TODO: not sure if we need value
        #self[:value] = parse ..(ast_rsc_param.value,opts)
        super
      end
    end

    class AttributePS < ParseStructure
      def initialize(arg,opts={})
        self[:name] = arg[0]
        self[:default] =  default_value(arg[1]) if arg[1]
        super
      end
     private
      def default_value(default_obj)
        if puppet_type?(default_obj,:string)
          default_obj.value
        elsif puppet_type?(default_obj,:name)
          default_obj.value
        else
          raise Error.new("unexpected type for an attribute default")
        end
      end
    end
    class RequireStatementPS < ParseStructure
    end
    class IncludeStatementPS < ParseStructure
    end

    class ParseStructure < Hash
      #TODO: temp if not called as stand alone utility
      class Error < NameError
      end
      #TODO: for debugging until override
      def initialize(ast_item=nil,opts={})
        return super() if ast_item.nil? 
        #TODO: just for debugging
        if keys.size == 0 #test to see if this is coming from a child calling super
          self[:instance_variables] = ast_item.instance_variables
        end
        self[:r8class] = self.class.to_s.gsub("XYZ::Puppet::","").to_sym
      end

      ###hacks for pp
      def pretty_print(q)      
        #TODO: may return an ordered hash
        pp_form().pretty_print(q)
      end

      def pp_form
        require '/root/R8Server/utils/internal/auxiliary.rb' #TODO: this must be taken out
        ret =  ActiveSupport::OrderedHash.new()
        #TODO: have each class optionally have klass.pp_key_order
        ret[:r8class] = self[:r8class] || self.class.to_s.gsub("XYZ::Puppet::","").to_sym
        each do |k,v|
          next if k == :r8class
          ret[k] = 
            if v.kind_of?(ParseStructure) then v.pp_form
            elsif v.kind_of?(Array) 
              v.map{|x|x.kind_of?(ParseStructure) ? x.pp_form : x}
            else v
          end
        end
        ret
      end
      ######

      def self.create(ast_fn,opts={})
        new(ast_fn,opts)
      end

      def self.puppet_type?(ast_item,types)
        types = Array(types)
        puppet_ast_classes = Array(types).inject({}){|h,t|h.merge(t => TreatedPuppetTypes[t])}
        puppet_ast_classes.each do |type, klass|
          raise Error.new("type #{type} not treated") if klass.nil?
          return type if ast_item.kind_of?(klass)
        end
        nil
      end
      def puppet_type?(ast_item,types)
        self.class.puppet_type?(ast_item,types)
      end
      TreatedPuppetTypes = {
        :hostclass => ::Puppet::Parser::AST::Hostclass,
        :definition => ::Puppet::Parser::AST::Definition,
        :resource => ::Puppet::Parser::AST::Resource,
        :collection => ::Puppet::Parser::AST::Collection,
        :if_statement => ::Puppet::Parser::AST::IfStatement,
        :case_statement => ::Puppet::Parser::AST::CaseStatement,
        :string => ::Puppet::Parser::AST::String,
        :name => ::Puppet::Parser::AST::Name,
        :function => ::Puppet::Parser::AST::Function,
        :var_def => ::Puppet::Parser::AST::VarDef,
        :relationship => ::Puppet::Parser::AST::Relationship,
      }
    end
  end
end

#monkey patches
class Puppet::Parser::AST::Definition
  attr_reader :name
end

####

file = ARGV[0]
file ||= "/root/r8server-repo/puppet-mysql/manifests/classes/master.pp"
Puppet[:manifest] = file
environment = "production"
krt = Puppet::Node::Environment.new(environment).known_resource_types
krt_code = krt.hostclass("").code
krt_code.children.each do |ast_item|
  r8_parse = XYZ::Puppet::ComponentPS.create(ast_item,{:foo => true})
  pp r8_parse
end
#pp krt_code
