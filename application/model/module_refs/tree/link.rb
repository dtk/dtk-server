module DTK; class ModuleRefs
  class Tree
    class Link
      attr_reader :tree
      def initialize(tree)
        @tree = tree
        @components = Array.new
      end
    end
  end
end; end
