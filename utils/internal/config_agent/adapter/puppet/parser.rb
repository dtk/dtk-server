#TODO: think better to move assumptions about ast form into the initialization functions to capture their assumptions
module Puppet
end
require 'puppet/resource'
require 'puppet/type'
require 'puppet/parser'

module DTK; class ConfigAgent; module Adapter; class Puppet
  module ParserMixin
    r8_nested_require('parser','modulefile')

    def parse_external_ref?(impl_obj)
      Modulefile.parse?(impl_obj)
    end

    def parse_given_module_directory(impl_obj)
      #only handling parsing of .pp now
      manifest_file_paths = impl_obj.all_file_paths().select{|path|path =~ /^manifests.+\.pp$/}
      ret = TopPS.new()
      opts = {:just_krt_code => true}
      all_errors = nil
      manifest_file_paths.each do |file_path|
        Log.info("Calling #{type()} and dtk processor on file #{file_path}")
        begin
          krt_code = parse_given_file_path__manifest(file_path,impl_obj,opts)
          ret.add_children(krt_code) unless all_errors #short-circuit once first error found
         rescue ParseErrors => errors
          all_errors = (all_errors ? all_errors.add(errors) : errors)
         rescue ParseError => error
          all_errors = (all_errors ? all_errors : ParseErrors.new(type())).add(error)
        end
      end
      raise all_errors if all_errors
      ret
    end

    #returns [config agent type, parse]
    #types are :component_defs, :template, :r8meta
    def parse_given_file_content(file_path,file_content)
      ret = [nil,nil]
      if file_path =~ /\.pp$/
        ret[0] = :component_defs
        ret[1] = parse_given_file_content__manifest(file_content)
      end
      ret
    end
   private

    PuppetParserLock = Mutex.new

    def parse_given_file_path__manifest(file_path,impl_obj,opts={})
      file_content = RepoManager.get_file_content({:path => file_path},impl_obj)
      parse_given_file_content__manifest(file_content,opts.merge(:file_path => file_path))
    end

    def parse_given_file_content__manifest(file_content,opts={})
      synchronize_and_handle_puppet_globals({:code => file_content, :ignoreimport => false},opts) do
        environment = "production"
        node_env = ::Puppet::Node::Environment.new(environment)
        known_resource_types = ::Puppet::Resource::TypeCollection.new(node_env)
        #needed to make more complicared because cannot call krt = ::Puppet::Node::Environment.new(environment).known_resource_types because perform_initial_import needs import set to false, but rest needs it set to true
        #fragment from perform_initial_import call with ::Puppet[:ignoreimport] = true set in middle
        parser = ::Puppet::Parser::Parser.new(node_env)
        parser.string = file_content
        ::Puppet[:ignoreimport] = true
        initial_import = parser.parse

        known_resource_types.import_ast(initial_import,"")
        krt_code = known_resource_types.hostclass("").code
        opts[:just_krt_code] ? krt_code : TopPS.new(krt_code)
      end
    end

    def synchronize_and_handle_puppet_globals(global_assignments,opts={},&block)
      ret = nil
      PuppetParserLock.synchronize do
        begin
          current_vals = global_assignments.keys.inject({}){|h,k|h.merge(k => ::Puppet[k])}
          curent_krt = Thread.current[:known_resource_types]
          global_assignments.each{|k,v|::Puppet[k]=v}
          Thread.current[:known_resource_types] = nil
          ret = yield
         rescue ::Puppet::Error => e
          raise normalize_puppet_error(e,opts[:file_path]) 
         rescue Exception => e
          raise e
         ensure
          current_vals.each{|k,v|::Puppet[k]=v}
          Thread.current[:known_resource_types] = curent_krt
        end
      end
      ret
    end

    def normalize_puppet_error(puppet_error,file_path)
      file_path ||= puppet_error.file || find_file_path(puppet_error.message)
      line = puppet_error.line || find_line(puppet_error.message)
      #TODO: strip stuff off error message
      msg = strip_message(puppet_error.message)
      single_error = ConfigAgent::ParseError.new(msg,file_path,line)
      #TODO: change when handle multiple errors
      ConfigAgent::ParseErrors.new(:puppet).add(single_error)
    end

    def find_file_path(msg)
      if msg =~ /at ([^ ]+):[0-9]+$/ 
        $1
      end
    end

    def  find_line(msg)
      if msg =~ /:([0-9]+$)/
        $1
      end
    end

    def strip_message(msg)
      ret = msg
      ret = ret.gsub(/Could not parse for environment production: /,"")
      ret = ret.gsub(/at [^ ]+:[0-9]+$/,"")
      ret
    end
   public
    class ParseStructure < SimpleHashObject
      #TODO: for debugging until override
      def initialize(ast_item=nil,opts={})
        return super() if ast_item.nil? 
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
        unless ignore?(ast_obj,opts)
          new(ast_obj,opts)
        end
      end

      #this can be overwritten
      def self.ignore?(ast_obj,opts={})
        nil
      end

      def self.puppet_type?(ast_item,types)
        types = Array(types)
        puppet_ast_classes = Array(types).inject({}){|h,t|h.merge(t => TreatedPuppetTypes[t])}
        puppet_ast_classes.each do |type, klass|
          raise ConfigAgent::ParseError.new("type #{type} not treated") if klass.nil?
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
        :resource_reference => ::Puppet::Parser::AST::ResourceReference,
        :string => ::Puppet::Parser::AST::String,
        :name => ::Puppet::Parser::AST::Name,
        :boolean => ::Puppet::Parser::AST::Boolean,
        :variable => ::Puppet::Parser::AST::Variable,
        :undef => ::Puppet::Parser::AST::Undef,
        :concat => ::Puppet::Parser::AST::Concat,
        :function => ::Puppet::Parser::AST::Function,
        :var_def => ::Puppet::Parser::AST::VarDef,
        :resource_defaults => ::Puppet::Parser::AST::ResourceDefaults,
        :ast_array => ::Puppet::Parser::AST::ASTArray,
        :ast_hash => ::Puppet::Parser::AST::ASTHash,
      }
      AstTerm = [:string,:name,:variable,:concat,:function,:boolean,:undef,:ast_array,:ast_hash]

      def parse_just_signatures?()
        @parse_just_signatures ||= R8::Config[:puppet][:parser][:parse_just_signatures] 
      end

    end

    #can be module or file
    class TopPS < ParseStructure
      def initialize(ast_array=nil,opts={})
        self[:children] = Array.new
        add_children(ast_array,opts)
        super
      end

      def add_children(ast_array,opts={})
        return unless ast_array
        ast_array.each do |ast_item|
          child = 
            if puppet_type?(ast_item,[:hostclass,:definition])
              ComponentPS.create(ast_item,opts)
            elsif puppet_type?(ast_item,[:var_def])
              nil
              #TODO: should this be ignored?
            else
              raise ConfigAgent::ParseError.new("Unexpected top level ast type (#{ast_item.class.to_s})")
            end
          self[:children] << child if child
        end
      end

      def each_component(&block)
        self[:children].each do |component_ps|
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
            raise ConfigAgent::ParseError.new("unexpected type for ast_item")
          end
        self[:type] = type
        self[:name] = ast_item.name

        if type == "definition"
          self[:only_one_per_node] = false
        end

        attributes = Array.new
        attributes << AttributePS.create_name_attribute() if puppet_type?(ast_item,:definition)
        (ast_item.context[:arguments]||[]).each{|arg|attributes << AttributePS.create(arg,opts)}
        self[:attributes] = attributes
begin
        children = parse_children(ast_item,opts)
        self[:children] = children if children and not children.empty?
rescue => e

pp [:error_child,ast_item.inspect]
parse_children(ast_item,opts)
  raise e
end

        super

      end
     private
      def self.ignore?(ast_obj,opts={})
        #TODO: make this configurable 
        #ignore components that have more than one qualification; tehy are mostly sub classes/defs
        #ast_obj.name =~ /::.+::/
        nil
      end

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

        return nil if puppet_type?(ast_item,types_to_ignore())
        if type = puppet_type?(ast_item,types_to_process())
          "parse__#{type}".to_sym
        elsif puppet_type?(ast_item,:definition)
          Log.error("need to implement nested class definitions")
          nil
        elsif puppet_type?(ast_item,:resource_defaults)
          Log.error("check whether should ignore resource_defaults in class def")
          nil
        else
          raise ConfigAgent::ParseError.new("unexpected ast type (#{ast_item.class.to_s})",self)
        end
      end

      def types_to_ignore()
        if parse_just_signatures?()
          [:var_def,:hostclass,:collection,:resource,:if_statement,:case_statement,:function,:relationship,:resource_reference]
        else
          [:var_def,:hostclass]
        end
      end
      def types_to_process()
        if parse_just_signatures?()
          []
        else
          [:collection,:resource,:if_statement,:case_statement,:function,:relationship,:resource_reference]
        end
      end

      def parse__collection(ast_item,opts)
        if ast_item.form == :exported
          ImportedCollectionPS.create(ast_item,opts)
        end
      end

      def parse__resource(ast_item,opts)
        #TODO: case on opts what is returned; here we are casing on just external resources
        return ExportedResourcePS.create_instances(ast_item,opts) if ast_item.exported
        if ResourcePS.builtin?(ast_item)
        else DefinedResourcePS.create_instances(ast_item,opts)
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
      def parse__resource_reference(ast_item,opts)
        ret = Array.new
        rsc_ref = ResourceReferencePS.create(ast_item,opts)
        ret << rsc_ref if rsc_ref
        ret
      end
    end

    class ResourcePS < ParseStructure
      def self.builtin?(ast_resource)
        puppet_type = ::Puppet::Type.type(ast_resource.type)
        puppet_type && puppet_type.to_s.gsub(/Puppet::Type::/,"").downcase.to_sym
      end

     private
      def self.resource_parameters_array(ast_resource,opts={})
        children = ast_resource.instances.children
        children.map do |ch|
          params = ch.parameters.children.map do |ast_rsc_param|
            ResourceParamNonTitlePS.create(ast_rsc_param,opts)
          end.compact
          params <<  ResourceTitlePS.create(ch.title,opts) unless opts[:no_title]
          params
        end
      end
      def name(ast_resource)
        ret = ast_resource.type
        if ret == "class"
          ast_title = ast_title(ast_resource)
          raise ConfigAgent::ParseError.new("unexpected title ast type (#{ast_title.class.to_s})") unless puppet_type?(ast_title,AstTerm)
          ret = ast_title.value
        end
        ret
      end

      def ast_title(ast_resource,opts={})
        children = ast_resource.instances.children
        #if this is called all children will agree on the title
        sample_child = children.first
        sample_child.title
      end
    end

    class DefinedResourcePS < ResourcePS
      def self.create_instances(ast_resource,opts={})
        resource_parameters_array(ast_resource,opts.merge(:no_title => true)).map do |params|
          new(ast_resource,params,opts)
        end
      end
      
      def initialize(ast_resource,params,opts={})
        self[:name] = name(ast_resource)
        self[:type] = type(ast_resource)
        (params||[]).each do |p|
          if p.kind_of?(StageResourceParam)
            self[:stage] = p
          else
            (self[:parameters] ||= Array.new) << p
          end
        end
        super(ast_resource,opts)
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
      def self.create_instances(ast_resource,opts={})
        resource_parameters_array(ast_resource,opts).map do |params|
          new(ast_resource,params,opts)
        end
      end

      def initialize(ast_resource,params,opts={})
        self[:name] = name(ast_resource)
        self[:parameters] =  params
        super(ast_resource,opts)
      end
      def is_exported_resource?() 
        true
      end
    end

    class ResourceParamPS < ParseStructure
      def initialize(name,value_ast,ast_rsc_param,opts={})
        self[:name] = name
        val = value(value_ast,opts)
        self[:value] = val if val
        super(ast_rsc_param,opts)
      end
     private
      def value(value_ast,opts)
        if puppet_type?(value_ast,:resource_reference)
          ResourceReferencePS.create(value_ast,opts)
        else
          TermPS.create(value_ast,opts) 
        end
      end
    end

    class ResourceParamNonTitlePS < ResourceParamPS
      def self.create(ast_rsc_param,opts={})
        case ast_rsc_param.param 
         #TODO: ccurrently throwing out require; this should be used to look for foreign resources
         when "require" then nil
         when "stage" then StageResourceParam.create(ast_rsc_param,opts)
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

    class StageResourceParam < ResourceParamPS
      def initialize(ast_rsc_ref,opts={})
        self[:name] = ast_rsc_ref.value.value
      end
    end

    class ResourceReferencePS < ParseStructure
      def initialize(ast_rsc_ref,opts={})
        self[:name] = name(ast_rsc_ref)
        super
      end
     private
      def name(ast_rsc_ref)
        ret = ast_rsc_ref.type
        if ret == "Class"
          ast_title = ast_title(ast_rsc_ref)
          raise ConfigAgent::ParseError.new("unexpected title ast type (#{ast_title.class.to_s})") unless puppet_type?(ast_title,AstTerm)
          ret = ast_title.value
        end
        ret
      end
      def ast_title(ast_rsc_ref)
        unless ast_rsc_ref.title
          raise ConfigAgent::ParseError.new("unexpected to not have title on resource reference")
        end
        children = ast_rsc_ref.title.children
        unless children.size == 1
          raise ConfigAgent::ParseError.new("unexpected to have number of resource ref children neq to 1")
        end
        children.first
      end
    end

    class AttributePS < ParseStructure
      def initialize(arg,opts={})
        self[:name] = arg[0]
        if arg[1]
          default_val = default_value(arg[1])
          self[:default] =  default_val if default_val
          self[:required] = opts[:required] if opts.has_key?(:required)
        else
          self[:required] = true
        end
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
        if puppet_type?(default_ast_obj,[:string,:name,:variable,:boolean,:ast_array,:ast_hash,:undef])
          TermPS.create(default_ast_obj)
        else
          Log.error("not treating type (#{default_ast_obj.class.to_s}) for an attribute default")
          nil
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
          else raise ConfigAgent::ParseError.new("Unexpected type (#{query.class.to_s}) in query argument of collection")
        end 
       super
      end

      #returns var bindings if any of there is a match
      def match_exported?(exp_rsc)
        return nil unless self[:type] == exp_rsc[:name]
        return VarMatches.new if self[:query].nil?
        self[:query].match_exported?(exp_rsc[:parameters])
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
          else raise ConfigAgent::ParseError.new("unexpected operation (#{coll_expr_ast.oper}) for collection expression")
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
          raise ConfigAgent::ParseError.new("unexpected type for collection expression")
        end
        self[:op] = "=="
        self[:name] = name
        self[:value] = TermPS.create(value_ast,opts)
        super
      end
      def attribute_expressions()
        [SimpleOrderedHash.new([{:name => self[:name]}, {:op => self[:op]}, {:value => self[:value]}])]
      end
      def structured_form()
        ["op",self[:op],self[:name],self[:value].structured_form()]
      end

      def match_exported?(exp_rsc_params)
        #TODO: treat ops other than  "=="
        return nil unless self[:op] == "=="
        matching_param = exp_rsc_params.find{|p|p[:name] == self[:name]}
        ret = matching_param && matching_param[:value].can_match?(self[:value])
        ret && ret.map{|x|x.merge(:name => self[:name])}
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
      def structured_form()
        ["op",self[:op],self[:arg1].structured_form(),self[:arg2].structured_form()]
      end

      def match_exported?(exp_rsc_params)
        case self[:op]
         when "and" then 
          if match1 = self[:arg1].match_exported?(exp_rsc_params) 
            if match2 = self[:arg2].match_exported?(exp_rsc_params)
              match1 + match2
            end
          end
         when "or" 
          self[:arg1].match_exported?(exp_rsc_params) ||self[:arg2].match_exported?(exp_rsc_params)
        end
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
            Log.error("unexpected statement in 'if statement' body having ast class (#{child_ast_item.class.to_s})")
            Array.new
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
         when :string then StringPS.new(ast_term,opts)
         when :boolean then BooleanPS.new(ast_term,opts)
         when :undef then UndefPS.new(ast_term,opts)
         when :function then FunctionPS.new(ast_term,opts)
         when :ast_array then ArrayPS.new(ast_term,opts)
         when :ast_hash then HashPS.new(ast_term,opts)
         else raise ConfigAgent::ParseError.new("type not treated as a term (#{ast_term.class.to_s})")
        end
      end
      def data_type()
        "string" 
      end
      def set_default_value?()
        true
      end
      def contains_variable?()
        nil
      end
      def is_variable?()
        nil
      end
      def variable_list()
        Array.new
      end
      def template?()
        nil
      end
      def default_value(opts={})
        to_s(opts)
      end
    end

    class VariablePS < TermPS
      def initialize(var_ast,opts={})
        self[:value] = var_ast.value
        super
      end
      def contains_variable?()
        true
      end
      def is_variable?()
        true
      end
      def variable_list()
        [self[:value]]
      end
      def to_s(opts={})
        val = self[:value]
        return val if opts[:just_variable_name]
        opts[:in_string] ? "${#{val}}" : "$#{val}"
      end

      def structured_form()
        ["variable",self[:value]]
      end

      def can_match?(ast_term)
        VarMatches.new.add(self,ast_term)
      end
    end

    module NameStringMixin
      def to_s(opts={})
        self[:value]
      end
      def structured_form()
        self[:value]
      end
                          
      def can_match?(ast_term)
        if ast_term.kind_of?(NamePS) or ast_term.kind_of?(StringPS) 
          self[:value] == ast_term[:value] ? VarMatches.new : nil
        elsif ast_term.kind_of?(VariablePS) 
          VarMatches.new.add(self,ast_term)
        end
      end
    end

    class NamePS < TermPS
      include NameStringMixin
      def initialize(name_ast,opts={})
        self[:value] = name_ast.value
        super
      end
    end

    class StringPS < TermPS
      include NameStringMixin
      def initialize(string_ast,opts={})
        self[:value] = string_ast.value
        super
      end
    end

    class BooleanPS < TermPS
      def initialize(boolean_ast,opts={})
        self[:value] = boolean_ast.value
        super
      end
      def data_type()
        "boolean" 
      end
      def to_s(opts={})
        self[:value] && self[:value].to_s
      end
    end

    class UndefPS < TermPS
      def initialize(undef_ast,opts={})
        super
      end
      def to_s(opts={})
        nil
      end
      def set_default_value?()
        nil
      end
    end

    class ArrayPS < TermPS
      def initialize(array_ast,opts={})
        self[:terms] = array_ast.children.map{|term_ast|TermPS.create(term_ast,opts)}
        super
      end
      def to_s(opts={})
        elements = self[:terms].map do |t|
          t.kind_of?(TermPS) ? t.to_s(opts.merge(:in_string => true)) : t.to_s
        end
        "[#{elements.join(",")}]"
      end
      def default_value(opts={})
        self[:terms].map do |t|
          t.kind_of?(TermPS) ? t.default_value(opts) : t.default_value()
        end
      end
      def data_type()
        'array' 
      end
      def can_match?(ast_term)
        if ast_term.kind_of?(VariablePS) 
          VarMatches.new.add(self,ast_term)
        elsif ast_term.kind_of?(ArrayPS)
          return nil unless self[:terms].size == ast_term[:terms].size
          ret = nil
          self[:terms].each_with_index do |t,i|
            return nil unless match = t.can_match?(ast_term[:terms][i])
            ret = (ret ? ret + match : match)
          end
          ret
        end
      end
    end

    class HashPS < TermPS
      def initialize(hash_ast,opts={})
        self[:key_values] = hash_ast.value.inject(Hash.new) do |h,(k,term_ast)|
          key = 
            if k.respond_to?(:value)
              k.value
            elsif k.respond_to?(:to_s)
              k.to_s
            else
              raise ConfigAgent::ParseError.new("unexpected hash key term (#{k.inspect})")
            end
          h.merge(key => TermPS.create(term_ast,opts))
        end
        super
      end
      def to_s(opts={})
        hash =  self[:key_values].inject(Hash.new) do |h,(k,t)|
          h.merge(k => t.kind_of?(TermPS) ? t.to_s(opts) : t.to_s())
        end
        hash.inspect()
      end
      def default_value(opts={})
        self[:key_values].inject(Hash.new) do |h,(k,t)|
          h.merge(k => t.kind_of?(TermPS) ? t.default_value(opts) : t.default_value())
        end
      end
      def data_type()
        'hash' 
      end
      def can_match?(ast_term)
        if ast_term.kind_of?(VariablePS) 
          VarMatches.new.add(self,ast_term)
        elsif ast_term.kind_of?(HashPS)
          return nil unless self[:key_values].keys == ast_term[:key_values].keys
          ret = nil
          self[:key_values].each do |k,v|
            rturn nil unless matching_val = ast_term[:key_values][k]
            return nil unless match = v.can_match?(matching_val)
            ret = (ret ? ret + match : match)
          end
          ret
        end
      end
    end

    module ConcatFunctionMixin
      def contains_variable?()
        self[:terms].each do |t|
          if t.kind_of?(TermPS)
            return true if t.contains_variable?()
          end
        end
        nil
      end
      def variable_list()
        ret = Array.new
        self[:terms].each{|t|ret += t.variable_list()}
        ret
      end
    end

    class ConcatPS < TermPS
      include ConcatFunctionMixin
      def initialize(concat_ast,opts={})
        self[:terms] = concat_ast.value.map{|term_ast|TermPS.create(term_ast,opts)}
        super
      end
      def to_s(opts={})
        self[:terms].map do |t|
          t.kind_of?(TermPS) ? t.to_s(opts.merge(:in_string => true)) : t.to_s
        end.join("")
      end

      def structured_form()
        ["fn","concat"] + self[:terms].map{|t|t.structured_form()}
      end

      def can_match?(ast_term)
        if ast_term.kind_of?(VariablePS) 
          VarMatches.new.add(self,ast_term)
        elsif ast_term.kind_of?(ConcatPS)
          #TODO: can be other ways to match
          return nil unless self[:terms].size == ast_term[:terms].size
          ret = nil
          self[:terms].each_with_index do |t,i|
            return nil unless match = t.can_match?(ast_term[:terms][i])
            ret = (ret ? ret + match : match)
          end
          ret
        end
      end
    end
    class FunctionPS < TermPS
      include ConcatFunctionMixin
      def initialize(fn_ast,opts={})
        self[:name] = fn_ast.name
        self[:terms] = fn_ast.arguments.children.map{|term_ast|TermPS.create(term_ast,opts)}
        super
      end
      def to_s(opts={})
        args = self[:terms].map do |t|
          t.kind_of?(TermPS) ? t.to_s(opts.merge(:in_string => true)) : t.to_s
        end.join(",")
        "#{self[:name]}(#{args})"
      end
       def structured_form()
         ["fn",self[:name]] + self[:terms].map{|t|t.structured_form()}
      end
      def template?()
        self[:name] == "template" ? self[:terms].first : nil
      end
      def can_match?(ast_term)
        if ast_term.kind_of?(VariablePS) then true
        elsif ast_term.kind_of?(FunctionPS)
          #TODO: can be other ways to match
          return nil unless self[:name] == ast_term[:name]
          return nil unless self[:terms].size == ast_term[:terms].size
          self[:terms].each_with_index{|t,i|return nil unless t.can_match?(ast_term[:terms][i])}
          true
        end
      end
    end
  end
end; end; end; end

#monkey patches
class Puppet::Parser::AST::Definition
  attr_reader :name
end
####

