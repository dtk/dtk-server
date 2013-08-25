module DTK; class Attribute
  class Pattern 
    class Node < self
      def self.create(pattern,node,opts={})
        if pattern =~ /^[0-9]+$/
          Type::ExplicitId.new(pattern,node)
        elsif pattern =~ /^[0-9a-zA-Z\-_]+$/
          node_name = node.get_field?(:display_name)
          attr_term = pattern
          Type::NodeLevel.new("node[#{node_name}]/attribute[#{attr_term}]")
        else
          raise ErrorParse.new(pattern)
        end
      end
    end
  end
end; end
