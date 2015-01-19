module DTK; class Component
  class IncludeModule
    class Recursive
      def initialize(parent)
        @parent = parent
        # mappoing from module name to implementations
        @module_mapping = Hash.new
      end
      def process_components!(components)
      end
    end
  end
end; end
