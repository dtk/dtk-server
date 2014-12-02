module DTK; class LinkDefContext
  class Value 
    class Component < self
      def initialize(term)
        super(term[:component_type])
      end
      def value()
        @component
      end
    end
  end
end; end      
