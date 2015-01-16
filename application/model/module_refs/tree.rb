#TODO: modle_branch used as what is indexed so it denotes namespace/module/version
module DTK
  class ModuleRefs
    # This module is used to build a hierarchical dependency tree and to detect conflicts
    class Tree 
      # assembly can be an assembly template or assembly instance
      def initialize(hash_params)
        @chiildren = Array.new
      end
      private :initialize
      def self.create(module_branch)
      end
      # Used to render an exml dependency tree
      def hash_form()
      end
     private
      
    end
  end
end
