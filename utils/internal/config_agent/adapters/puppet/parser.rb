require 'rubygems'
require 'pp'
require 'puppet'

module XYZ
  class Puppet
    class ParseStructure < Hash
      def self.puppet_type?(ast_item,type)
        puppet_ast_class = TreatedPuppetTypes[type]
        unless puppet_ast_class
          raise Error.new("type #{type} not treated")
        end
        ast_item.kind_of?(puppet_ast_class)
      end
      def puppet_type?(ast_item,type)
        self.class.puppet_type?(ast_item,type)
      end
    end

    class ComponentPS < ParseStructure
      #TODO: use opts to indiacte what to parse
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
        self[:attributes] = (ast_item.context[:arguments]||[]).map{|arg|AttributePS.new(arg,opts)}
        children = parse_children(ast_item,opts)
        self[:children] = children if children and not children.empty?
      end
     private
      def parse_children(ast_item,opts)
        return nil unless code = ast_item.context[:code]
        ret = Array.new
        (code.children||[]).each do |child_ast_item|
          if fn = process_fn(child_ast_item,opts)
            ret += Array(send(fn,child_ast_item,opts))
          end
        end
        ret
      end 

      def parse_collection(ast_item,opts)
        [ast_item.class,ast_item.instance_variables]
      end

      def parse_resource(ast_item,opts)
        #TODO: case on opts what is returned; here we are casing on just external resources
        if ast_item.exported
          ExportedResourcePS.new(ast_item,opts)
        end
      end

      def parse_ifstatement(ast_item,opts)
        #TODO: this flattens the "if call" and returns both sides; whether this shoudl be done may be dependent on ops
        IfStatementPS.flat_statement_iter(ast_item,opts) do |child_ast_item|
          if puppet_type?(child_ast_item,:resource)
            parse_resource(child_ast_item,opts)
          elsif puppet_type?(child_ast_item,:function) and child_ast_item.name == "include"
            #TODO: not sure if need to load in what is included
            nil
          else
            raise Error.new("unexpceted statement in 'if statement' body")
          end
        end.compact
      end

      def process_fn(ast_item,opts) 
        return nil if IgnoreListWhenNested.find{|klass|ast_item.kind_of?(klass)}
        if puppet_type?(ast_item,:collection)
          :parse_collection
        elsif puppet_type?(ast_item,:resource)
          :parse_resource
        elsif puppet_type?(ast_item,:if_statement)
          :parse_ifstatement
        else
          raise Error.new("unexpected ast type (#{ast_item.class.to_s})")
        end
      end
      #TODO: make  list function of opts
      #btter unify with TreatedPuppetTypes
      IgnoreListWhenNested = 
        [
         ::Puppet::Parser::AST::CaseStatement,
         ::Puppet::Parser::AST::Function,
         ::Puppet::Parser::AST::VarDef,
         ::Puppet::Parser::AST::Relationship
        ]
    end
    class ExportedResourcePS < ParseStructure
      def initialize(ast_resource,opts={})
        self[:type] = ast_resource.type
        self[:paramters] =  resource_parameters(ast_resource,opts)
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
            ResourceParamPS.new(ast_rsc_param,opts)
          else
            raise Error.new("Unexpected child of resource (#{ast_rsc_param.class.to_s})")
          end
        end
      end
    end

    module ConditionalStatementsMixin
      def flat_statement_iter(ast_item,opts={},&block)
        next_level_statements(ast_item).each do |child_ast_item|
          if puppet_type?(child_ast_item,:resource)
            block.call(child_ast_item)
          elsif puppet_type?(child_ast_item,:function)
            block.call(child_ast_item)
          elsif puppet_type?(child_ast_item,:if_statement)
            IfStatementPS.flat_statement_iter(child_ast_item,opts,&block)
          elsif puppet_type?(child_ast_item,:case_statement)
            CaseStatementPS.flat_statement_iter(child_ast_item,opts,&block)
          else
            raise Error.new("unexpceted statement in 'if statement' body")
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
      end
    end

    class AttributePS < ParseStructure
      def initialize(arg,opts={})
        self[:name] = arg[0]
        self[:default] =  default_value(arg[1]) if arg[1]
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
    class ParseStructure < Hash
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
      }
    end
  end
end

#monkey patches
class Puppet::Parser::AST::Definition
  attr_reader :name
end

class Puppet::Parser::AST::ResourceParam
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
  pp  XYZ::Puppet::ComponentPS.new(ast_item,{:foo => true})
end
#pp krt_code
