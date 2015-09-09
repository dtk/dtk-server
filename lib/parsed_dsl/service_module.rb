module DTK
  module ParsedDSL
    class ServiceModule
      def initialize
        @empty = true
        @module_refs    = nil
        @assembly_tasks = nil
      end

      def add(info =  {})
        @empty = false
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
