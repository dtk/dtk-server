require 'rubygems'
require 'pp'
require 'puppet'

module XYZ
  class Puppet
    class ParseStructure < Hash
    end
    class ComponentPS < ParseStructure
      #TODO: use opts to indiacte what to parse
      def initialize(ast_item,opts={})
        type =
          if ast_item.kind_of?(::Puppet::Parser::AST::Hostclass)
            "puppet_class"
          elsif ast_item.kind_of?(::Puppet::Parser::AST::Definition)
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
        (code.children||[]).map do |child_ast_item|
          if fn = process_fn(child_ast_item,opts)
            send(fn,child_ast_item,opts)
          end
        end.compact
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

      def parse_debug(ast_item,opts)
        [ast_item.type,ast_item.class,ast_item.instance_variables]
      end

      def process_fn(ast_item,opts) 
        return nil if IgnoreListWhenNested.find{|klass|ast_item.kind_of?(klass)}
        if ast_item.kind_of?(::Puppet::Parser::AST::Collection)
          :parse_collection
        elsif ast_item.kind_of?(::Puppet::Parser::AST::Resource)
          :parse_resource
        else
          raise Error.new("unexpected ast type (#{ast_item.class.to_s})")
        end
      end
      #TODO: make inotre list function of opts
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
        #TODO: for bedugging to make sure we did no miss an impofrtant paramter
        self[:fields] = ast_resource.instance_variables 
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
            #TODO: stub
            [:resource_param,ast_rsc_param.instance_variables]
          else
            raise Error.new("Unexpected child of resource (#{ast_rsc_param.class.to_s})")
          end
        end
      end
    end

    class AttributePS < ParseStructure
      def initialize(arg,opts={})
        self[:name] = arg[0]
        self[:default] =  default_value(arg[1]) if arg[1]
      end
     private
      def default_value(default_obj)
        if default_obj.kind_of?(::Puppet::Parser::AST::String)
          default_obj.value
        elsif default_obj.kind_of?(::Puppet::Parser::AST::Name)
          default_obj.value
        else
          raise Error.new("unexpected type for an attribute default")
        end
      end
    end
  end
end

#monkety patches
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
  pp  XYZ::Puppet::ComponentPS.new(ast_item,{:foo => true})
end
#pp krt_code
