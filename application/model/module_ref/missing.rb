module DTK
  class ModuleRef
    class Missing
      attr_reader :module_name,:namespace
      def initialize(module_name,namespace)
        @module_name = module_name
        @namespace = namespace
      end

      def error
       Error.new(@module_name,@namespace)
      end

      class Error < ErrorUsage
        def initialize(module_name,namespace)
          super("Missing module ref '#{namespace}:#{module_name}'")
        end
      end
    end
  end
end

