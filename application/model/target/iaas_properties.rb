module DTK
  class Target
    class IAASProperties
      attr_reader :name,:properties
      def initialize(name,iaas_properties)
        @name = name
        @properties = iaas_properties
      end
      def self.check_and_process(iaas_type,iaas_properties)
        CommandAndControl.check_and_process_iaas_properties(iaas_type,iaas_properties)
      end
    end
  end
end

