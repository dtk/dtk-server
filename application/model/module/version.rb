module DTK
  class ModuleVersion < String
    def self.create_for_assembly(assembly)
      AssemblyModule.new(assembly)
    end

    class AssemblyModule < self
      attr_reader :assembly_name
     private
      def initialize(assembly)
        @assembly_name = assembly_name(assembly)
        super(version_string(assembly))
      end
      def assembly_name(assembly)
        assembly.get_field?(:display_name)
      end
      def version_string(assembly_name)
        "assembly--#{assembly_name}"
      end
    end
  end
end
