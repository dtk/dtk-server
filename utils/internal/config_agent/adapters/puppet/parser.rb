#TODO: think better to move assumptions about ast form into the initialization functions to capture their assumptions
require 'rubygems'
require 'puppet'

module XYZ
  class Puppet
    class ParseStructure < SimpleHashObject
      #TODO: temp if not called as stand alone utility
      class ParseError < NameError
      end
      #TODO: for debugging until override
      def initialize(ast_item=nil,opts={})
        return super() if ast_item.nil? 
        #TODO: just for debugging
        if keys.size == 0 #test to see if this is coming from a child calling super
          self[:instance_variables] = ast_item.instance_variables
        end
      end

      #### used in generate_meta
      def config_agent_type()
        :puppet
      end
      #These all get ovewritten for matching class
      def is_defined_resource?() 
        nil
      end
      def is_exported_resource?()
        nil
      end
      def is_imported_collection?()
        nil
      end
      def is_attribute?()
        nil
      end
      ######
      ###hacks for pp
      def pretty_print(q)      
        #TODO: may return an ordered hash
        pp_form().pretty_print(q)
      end

      def pp_form
        ret =  SimpleOrderedHash.new()
        #TODO: have each class optionally have klass.pp_key_order
        ret[:r8class] = self[:r8class] || self.class.to_s.gsub("XYZ::Puppet::","").gsub(/PS$/,"").to_sym
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

      def self.create(ast_obj,opts={})
        new(ast_obj,opts)
      end

      def self.puppet_type?(ast_item,types)
        types = Array(types)
        puppet_ast_classes = Array(types).inject({}){|h,t|h.merge(t => TreatedPuppetTypes[t])}
        puppet_ast_classes.each do |type, klass|
          raise ParseError.new("type #{type} not treated") if klass.nil?
          return type if ast_item.class == klass
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
        :resource_param => ::Puppet::Parser::AST::ResourceParam,
        :collection => ::Puppet::Parser::AST::Collection,
        :coll_expr => ::Puppet::Parser::AST::CollExpr,
        :if_statement => ::Puppet::Parser::AST::IfStatement,
        :case_statement => ::Puppet::Parser::AST::CaseStatement,
        :relationship => ::Puppet::Parser::AST::Relationship,
        :string => ::Puppet::Parser::AST::String,
        :name => ::Puppet::Parser::AST::Name,
        :variable => ::Puppet::Parser::AST::Variable,
        :concat => ::Puppet::Parser::AST::Concat,
        :function => ::Puppet::Parser::AST::Function,
        :var_def => ::Puppet::Parser::AST::VarDef,
      }
      AstTerm = [:string,:name,:variable,:concat]
    end

    class ModulePS < ParseStructure
      def initialize(ast_array,opts={})
        children = ast_array.children.map do |ast_item|
          if puppet_type?(ast_item,[:hostclass,:definition])
            ComponentPS.create(ast_item,opts)
          else
            raise ParseError("Unexpected top level ast type (#{ast_item.class.to_s})")
          end
        end.compact
        self[:children] = children
        super
      end
      def each_component(&block)
        (self[:children]||[]).each do |component_ps|
          if component_ps.kind_of?(ComponentPS)
            block.call(component_ps)
          end
        end
      end
    end


    class ComponentPS < ParseStructure
      #TODO: use opts to specify what to parse and what to ignore
      def initialize(ast_item,opts={})
        type =
          if puppet_type?(ast_item,:hostclass)
            "class"
          elsif puppet_type?(ast_item,:definition)
            "definition"
          else
            raise ParseError.new("unexpected type for ast_item")
          end
        self[:type] = type
        self[:name] = ast_item.name

        attributes = Array.new
        attributes << AttributePS.create_name_attribute() if puppet_type?(ast_item,:definition)
        (ast_item.context[:arguments]||[]).each{|arg|attributes << AttributePS.create(arg,opts)}
        self[:attributes] = attributes

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
        return ret unless child_ast_item
        if fn = process_fn(child_ast_item,opts)
          child_parse = send(fn,child_ast_item,opts)
          ret = child_parse.kind_of?(Array) ? child_parse : (child_parse ? [child_parse] : Array.new)
        end
        ret
      end

      def process_fn(ast_item,opts) 
        #TODO: make what is ignored and treated fn of opts
        types_to_ignore = [:var_def]
        types_to_process = [:collection,:resource,:if_statement,:case_statement,:function,:relationship]
        return nil if puppet_type?(ast_item,types_to_ignore)
        if type = puppet_type?(ast_item,types_to_process)
          "parse__#{type}".to_sym
        else
          raise ParseError.new("unexpected ast type (#{ast_item.class.to_s})")
        end
      end

      def parse__collection(ast_item,opts)
        if ast_item.form == :exported
          ImportedCollectionPS.create(ast_item,opts)
        end
      end

      def parse__resource(ast_item,opts)
        #TODO: case on opts what is returned; here we are casing on just external resources
        if ast_item.exported
          ExportedResourcePS.create(ast_item,opts)
        elsif not ResourcePS.builtin?(ast_item)
          DefinedResourcePS.create(ast_item,opts)
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

      def parse__relationship(ast_item,opts)
        ret = Array.new
        ret += parse_child(ast_item.left,opts) 
        ret += parse_child(ast_item.right,opts) 
        ret
      end
    end

    class ResourcePS < ParseStructure

      def self.builtin?(ast_resource)
        ::Puppet::Type.type(ast_resource.type)
      end
     private
      def name(ast_resource)
        ret = ast_resource.type
        if ret == "class"
          ast_title = ast_title(ast_resource)
          raise ParseError.new("unexpected title ast type (#{ast_title.class.to_s})") unless puppet_type?(ast_title,AstTerm)
          ret = ast_title.value
        end
        ret
      end
      def resource_parameters(ast_resource,opts={})
        ret = Array.new
        if ast_title = ast_title(ast_resource,opts)
          ret << ResourceTitlePS.create(ast_title,opts)
        end
        ast_params(ast_resource,opts).each do |ast_rsc_param|
          if puppet_type?(ast_rsc_param,:resource_param)
            param = ResourceParamNonTitlePS.create(ast_rsc_param,opts)
            ret << param if param
          else
            raise ParseError.new("Unexpected child of resource (#{ast_rsc_param.class.to_s})")
          end
        end
        ret
      end

      def ast_params(ast_resource,opts={})
        children = ast_resource.instances.children
        unless children.size == 1
          raise ParseError.new("unexpected to have number of resource children neq to 1")
        end
        children.first.parameters.children
      end
      def ast_title(ast_resource,opts={})
        children = ast_resource.instances.children
        unless children.size == 1
          raise ParseError.new("unexpected to have number of resource children neq to 1")
        end
        children.first.title
      end
    end

    class DefinedResourcePS < ResourcePS
      def initialize(ast_resource,opts={})
        self[:name] = name(ast_resource)
        self[:type] = type(ast_resource)
        super
      end
      def is_defined_resource?() 
        true
      end
     private
      def type(ast_resource)
        ast_resource.type == "class" ? "definition" : "class"
      end
    end
    class ExportedResourcePS < ResourcePS
      def initialize(ast_resource,opts={})
        self[:name] = name(ast_resource)
        self[:paramters] =  resource_parameters(ast_resource,opts)
        super
      end
      def is_exported_resource?() 
        true
      end
    end

    class ResourceParamPS < ParseStructure
      def initialize(name,value_ast_term,ast_rsc_param,opts={})
        self[:name] = name
        self[:value] = TermPS.create(value_ast_term,opts) if value_ast_term
        super(ast_rsc_param,opts)
      end
    end

    class ResourceParamNonTitlePS < ResourceParamPS
      def self.create(ast_rsc_param,opts={})
        #TODO: ccurrently throwing out require; this should be used to look for foreign resources
        if ast_rsc_param.param == "require"
          nil
        else
          name = ast_rsc_param.param        
          value_ast_term = ast_rsc_param.value
          new(name,value_ast_term,ast_rsc_param,opts)
        end
      end
    end

    class ResourceTitlePS < ResourceParamPS
      def self.create(value_ast_term,opts={})
        new("title",value_ast_term,value_ast_term,opts)
      end
    end


    class AttributePS < ParseStructure
      def initialize(arg,opts={})
        self[:name] = arg[0]
        self[:default] =  default_value(arg[1]) if arg[1]
        self[:required] = opts[:required] if opts.has_key?(:required)
        super
      end
      def is_attribute?() 
        true
      end

      def self.create_name_attribute()
        new(["name"],{:required => true})
      end
     private
      def default_value(default_ast_obj)
        if puppet_type?(default_ast_obj,[:string,:name,:variable])
          TermPS.create(default_ast_obj)
        else
          raise ParseError.new("unexpected type for an attribute default")
        end
      end
    end


    class ImportedCollectionPS < ResourcePS
      def initialize(ast_coll,opts={})
        self[:type] = ast_coll.type
        query = ast_coll.query
        type = puppet_type?(query,:coll_expr)
        self[:query] =  
          case type
           when :coll_expr then CollExprPS.create(query,opts)
          else raise ParseError.new("Unexpected type (#{query.class.to_s}) in query argument of collection")
        end 
       super
      end
      def is_imported_collection?()
        true
      end
    end

    class CollExprPS < ParseStructure
      def self.create(coll_expr_ast,opts={})
        case coll_expr_ast.oper
          when "==" then CollExprAttributeExpressionPS.new(coll_expr_ast,opts)
          when "and", "or" then CollExprLogicalConnectivePS.new(coll_expr_ast,opts)
          else raise ParseError.new("unexpected operation (#{coll_expr_ast.oper}) for collection expression")
        end
      end
    end
    
    class CollExprAttributeExpressionPS < CollExprPS
      def initialize(coll_expr_ast,opts)
        #TODO: if both test1 and test2 are names guessing that first one is attribute name
        name = nil
        value_ast = nil
        if puppet_type?(coll_expr_ast.test1,:name)
          name = coll_expr_ast.test1.value
          value_ast = coll_expr_ast.test2
        elsif puppet_type?(coll_expr_ast.test2,:name)
          name = coll_expr_ast.test2.value
          value_ast = coll_expr_ast.test1
        end
        unless name and value_ast
          raise ParseError.new("unexpected type for collection expression")
        end
        self[:op] = "=="
        self[:name] = name
        self[:value] = TermPS.create(value_ast,opts)
        super
      end
      def attribute_expressions()
        [SimpleOrderedHash.new([{:name => self[:name]}, {:op => self[:op]}, {:value => self[:value]}])]
      end
     end
     class CollExprLogicalConnectivePS < CollExprPS
      def initialize(coll_expr_ast,opts)
        self[:op] = coll_expr_ast.oper
        self[:arg1]  = CollExprPS.create(coll_expr_ast.test1,opts)
        self[:arg2]  = CollExprPS.create(coll_expr_ast.test2,opts)
        super
      end
      def attribute_expressions()
        ret = Array.new
        [:arg1,:arg2].each{|index|ret += self[index].attribute_expressions()}
        ret
      end
    end

    module ConditionalStatementsMixin
      def flat_statement_iter(ast_item,opts={},&block)
        next_level_statements(ast_item).each do |child_ast_item|
          just_pass_thru = puppet_type?(child_ast_item,[:resource,:function,:collection,:var_def])
          if just_pass_thru
            block.call(child_ast_item)
          elsif puppet_type?(child_ast_item,:if_statement)
            IfStatementPS.flat_statement_iter(child_ast_item,opts,&block)
          elsif puppet_type?(child_ast_item,:case_statement)
            CaseStatementPS.flat_statement_iter(child_ast_item,opts,&block)
          else
            raise ParseError.new("unexpected statement in 'if statement' body having ast class (#{child_ast_item.class.to_s})")
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

    module RequireIncludeClassMixin
      #defining create to handle case that there could be multiple items created
      def create(ast_fn,opts={})
        ast_fn.arguments.children.map do |term_ast|
          if parsed_term = TermPS.create(term_ast,opts)
            new(parsed_term,ast_fn,opts)
          end
        end.compact
      end
      private
    end
    module RequireIncludeInstanceMixin
      private
      def initialize(parsed_term,ast_fn,opts={})
        self[:term] = parsed_term
        super(ast_fn,opts)
      end
    end

    class RequireStatementPS < ParseStructure
      extend RequireIncludeClassMixin; include RequireIncludeInstanceMixin
    end
    class IncludeStatementPS < ParseStructure
      extend RequireIncludeClassMixin; include RequireIncludeInstanceMixin
    end

    class TermPS < ParseStructure
      def self.create(ast_term,opts={})
        treated_type = puppet_type?(ast_term,AstTerm)
        case treated_type
         when :variable then VariablePS.new(ast_term,opts)
         when :name then NamePS.new(ast_term,opts)
         when :concat then ConcatPS.new(ast_term,opts)
         when :string then ast_term.value
         else raise ParseError.new("type not treated as a term (#{ast_term.class.to_s})")
        end
      end
      def contains_variable?()
        type = puppet_type?(ast_term,AstTerm)
        case type
          when :variable then true
          when :name,:string then nil
        end
      end
    end

    class VariablePS < TermPS
      def initialize(var_ast,opts={})
        self[:value] = var_ast.value
        super
      end
      def to_s(opts={})
        val = self[:value]
        opts[:in_string] ? "${#{val}}" : "$#{val}"
      end
    end

    class NamePS < TermPS
      def initialize(name_ast,opts={})
        self[:value] = name_ast.value
        super
      end
      def to_s(opts={})
        self[:value]
      end
    end

    class ConcatPS < TermPS
      def initialize(concat_ast,opts={})
        self[:terms] = concat_ast.value.map{|term_ast|TermPS.create(term_ast,opts)}
        super
      end
      def to_s(opts={})
        self[:terms].map do |t|
          t.kind_of?(TermPS) ? t.to_s(:in_string => true) : t.to_s
        end.join("")
      end
      def contains_variable?()
        self[:terms].each do |t|
          if t.kind_of?(TermPS)
            return true if t.contains_variable?()
          end
        end
        nil
      end
    end
  end
end

#monkey patches
class Puppet::Parser::AST::Definition
  attr_reader :name
end
####
