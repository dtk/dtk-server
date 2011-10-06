require 'rubygems'
require 'pp'
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

      def self.create(ast_fn,opts={})
        new(ast_fn,opts)
      end

      def self.puppet_type?(ast_item,types)
        types = Array(types)
        puppet_ast_classes = Array(types).inject({}){|h,t|h.merge(t => TreatedPuppetTypes[t])}
        puppet_ast_classes.each do |type, klass|
          raise ParseError.new("type #{type} not treated") if klass.nil?
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
            "puppet_class"
          elsif puppet_type?(ast_item,:definition)
            "puppet_definition"
          else
            raise ParseError.new("unexpected type for ast_item")
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
        if fn = process_fn(child_ast_item,opts)
          child_parse = send(fn,child_ast_item,opts)
          child_parse.kind_of?(Array) ? child_parse : (child_parse ? [child_parse] : Array.new)
        else
          Array.new
        end
      end

      def process_fn(ast_item,opts) 
        #TODO: make what is ignored and treated fn of opts
        types_to_ignore = [:var_def,:relationship]
        types_to_process = [:collection,:resource,:if_statement,:case_statement,:function]
        return nil if puppet_type?(ast_item,types_to_ignore)
        if type = puppet_type?(ast_item,types_to_process)
          "parse__#{type}".to_sym
        else
          raise ParseError.new("unexpected ast type (#{ast_item.class.to_s})")
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
        elsif resource_instance_foreign_module?(ast_item)
          ForeignResourcePS.create(ast_item,opts)
        end
      end

      def resource_instance_foreign_module?(ast_item)
        #TODO: think this needs refinement; also see if we can simple test to rule out builtin
        ast_item.type =~ /::/
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

    class ForeignResourcePS < ParseStructure
      def initialize(ast_resource,opts={})
        self[:type] = ast_resource.type
        super
      end
    end

    class ResourcePS < ParseStructure
     private
      def resource_parameters(ast_resource,opts)
        children = ast_resource.instances.children
        unless children.size == 1
          raise ParseError.new("unexpected to have number of resource children neq to 1")
        end
        ret = Array.new
        if ast_title = children.first.title
          if puppet_type?(ast_title,AstTerm)
            ret << ResourceTitlePS.create(ast_title,opts)
          else
            raise ParseError.new("Unexpected resource title type (#{ast_title.class.to_s})")
          end
        end

        params = children.first.parameters.children
        params.each do |ast_rsc_param|
          if puppet_type?(ast_rsc_param,:resource_param)
            ret << ResourceParamPS.create(ast_rsc_param,opts)
          else
            raise ParseError.new("Unexpected child of resource (#{ast_rsc_param.class.to_s})")
          end
        end
        ret
      end
    end

    class ExportedResourcePS < ResourcePS
      def initialize(ast_resource,opts={})
        self[:type] = ast_resource.type
        self[:paramters] =  resource_parameters(ast_resource,opts)
        super
      end
    end

    class ExportedCollectionPS < ResourcePS
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
    end

    class CollExprPS < ParseStructure
      def initialize(coll_expr_ast,opts={})
        case coll_expr_ast.oper
          when "==" then initialize__eq_op(coll_expr_ast,opts)
          else raise ParseError.new("unexpected operation (#{coll_expr_ast.oper}) for collection expression")
        end
        super
      end
     private
      def initialize__eq_op(coll_expr_ast,opts)
        name = nil
        value_ast = nil
        if puppet_type?(coll_expr_ast.test1,:name)
          unless puppet_type?(coll_expr_ast.test2,:name)
            name = coll_expr_ast.test1.value
            value_ast = coll_expr_ast.test2
          end
        elsif puppet_type?(coll_expr_ast.test2,:name)
          unless puppet_type?(coll_expr_ast.test1,:name)
            name = coll_expr_ast.test2.value
            value_ast = coll_expr_ast.test1
          end
        end
        unless name and value_ast
          raise ParseError.new("unexpected type for collection expression")
        end
        self[:name] = name
        self[:value] = TermPS.create(value_ast,opts)
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

    class ResourceParamPS < ParseStructure
      def initialize(ast_rsc_param,opts={})
        self[:name] = ast_rsc_param.param
        #TODO: not sure if we need value
        #self[:value] = parse ..(ast_rsc_param.value,opts)
        super
      end
    end

    class ResourceTitlePS < ParseStructure
      def initialize(ast_term,opts={})
        self[:name] = "title"
        #TODO: not sure if we need value
        #self[:value] = parse ..(ast_term,opts)
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
          raise ParseError.new("unexpected type for an attribute default")
        end
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
    end

    class VariablePS < TermPS
      def initialize(var_ast,opts={})
        self[:value] = var_ast.value
        super
      end
    end

    class NamePS < TermPS
      def initialize(name_ast,opts={})
        self[:value] = name_ast.value
        super
      end
    end

    class ConcatPS < TermPS
      def initialize(concat_ast,opts={})
        self[:terms] = concat_ast.value.map{|term_ast|TermPS.create(term_ast,opts)}
        super
      end
    end
  end
end

#monkey patches
class Puppet::Parser::AST::Definition
  attr_reader :name
end
####
