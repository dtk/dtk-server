module DTK; class Attribute
  class Pattern 
    class Node < self
      def self.create(pattern,node,opts={})
        if pattern =~ /^[0-9]+$/
          Type::ExplicitId.new(pattern,node)
        else
          raise ErrorParse.new(pattern)
        end
      end
    end
  end
end; end
