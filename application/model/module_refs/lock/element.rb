module DTK; class ModuleRefs
  class Lock
    class Element 
      attr_reader :namespace,:module_name,:level,:children_module_names
      attr_accessor :implementation,:module_branch
      def initialize(namespace,module_name,level,subtree_module_names=[])
        @namespace = namespace
        @module_name = module_name
        @level = level
        @children_module_names = subtree_module_names
        @implementation = nil
        @module_branch = nil
      end

      def children_and_this_module_names()
        [@module_name] + @children_module_names
      end
    end
  end
end; end

