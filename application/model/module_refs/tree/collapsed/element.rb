module DTK; class ModuleRefs; class Tree
  class Collapsed
    class Element 
      attr_reader :namespace,:module_name,:level
      attr_writer :implementation
      def initialize(namespace,module_name,level)
        @namespace = namespace
        @module_name = module_name
        @level = level
      end
    end
  end
end; end; end
