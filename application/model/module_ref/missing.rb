module DTK
  class ModuleRef
    class Missing
      attr_reader :module_name,:namespace
      def initialize(module_name,namespace)
        @module_name = module_name
        @namespace = namespace
      end
    end
  end
end

