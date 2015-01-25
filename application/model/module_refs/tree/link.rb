module DTK; class ModuleRefs
  class Tree
    class Link
      attr_reader :module_ref
      def initialize(module_ref)
        @module_ref = module_ref
        @components = Array.new
        @tree = nil
      end
      def recursive_add_module_refs!(tree_top)
      end
    end
  end
end; end
