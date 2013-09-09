module DTK
  class ModuleVersion < String
    def self.create_for_assembly(assembly)
      AssemblyModule.new(assembly)
    end

    class AssemblyModule < self
      def initialize(assembly)
        super(version_string(assembly))
      end
     private
      def version_string(assembly)
        "assembly--#{assembly.get_field?(:display_name)}"
      end
    end
  end
end
