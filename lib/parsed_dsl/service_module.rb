module DTK
  module ParsedDSL
    class ServiceModule
      def initialize
        @empty               = true
        @assembly_raw_hashes = {}
        @display_name        = nil
        @module_refs         = nil
        @assembly_workflows  = nil
      end

      attr_reader :display_name, :assembly_raw_hashes

      def component_module_refs
        (@module_refs && @module_refs.component_modules) || {}
      end

      def assembly_workflows
        @assembly_workflows || {}
      end

      def add_assembly_raw_hash(name, raw_hash)
        @assembly_raw_hashes[name] = raw_hash
      end

      def add(info =  {})
        @empty              = false
        @display_name       = info[:display_name]
        @module_refs        = info[:module_refs]
        @assembly_workflows = info[:assembly_workflows]
        self
      end

      def empty?
        @empty
      end

    end
  end
end
