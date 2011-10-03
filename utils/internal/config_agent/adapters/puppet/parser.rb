require 'rubygems'
require 'pp'
require 'puppet'

module XYZ
  class Puppet
    class ParseStructure < Hash
    end
    class ComponentPS < ParseStructure
      def initialize(ast_item)
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
          self[:attributes] = (ast_item.context[:arguments]||[]).map{|arg|AttributePS.new(arg)}
      end
    end 

    class AttributePS < ParseStructure
      def initialize(arg)
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
    pp XYZ::Puppet::ComponentPS.new(ast_item)
end
#pp krt_code
