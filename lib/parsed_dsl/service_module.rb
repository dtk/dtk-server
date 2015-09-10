module DTK
  module ParsedDSL
    class ServiceModule
      def initialize
        @empty          = true
        @display_name   = nil
        @module_refs    = nil
        @assembly_tasks = nil
      end

      attr_reader :display_name

      def component_module_refs
        (@module_refs && @module_refs.component_modules) || {}
      end

      def assembly_tasks
        @assembly_tasks || {}
      end

      def add(info =  {})
        @empty          = false
        @display_name   = info[:display_name]
        @module_refs    = info[:module_refs]
        @assembly_tasks = info[:assembly_tasks]
        self
      end

      def empty?
        @empty
      end

    end
  end
end
