module DTK; class Attribute
  class Pattern 
    class Node < self
      def self.create(pattern,node,_opts={})
        if pattern =~ /^[0-9]+$/
          return Type::ExplicitId.new(pattern,node)
        end
        split_term = pattern.split("/")
        node_name = node.get_field?(:display_name)
        case split_term.size          
          when 1 
            Type::NodeLevel.new("node[#{node_name}]/attribute[#{split_term[0]}]")        
          when 2 
            Type::ComponentLevel.new("node[#{node_name}]/component[#{split_term[0]}]/attribute[#{split_term[1]}]")
          else        
            raise ErrorUsage::Parsing::Term.new(pattern,:node_attribute)
        end
      end
    end
  end
end; end
