module DTK
  class Target
    class IAASProperties
      attr_reader :name,:properties
      # IAASProperties.new will be called with 
      #  :name and :iaas_properties, or with
      # :target_instance
      def initialize(hash_args)
        @name = hash_args[:name]
        @iaas_properties = hash_args[:iaas_properties]
        @target_instance = hash_args[:target_instance]
      end

      def self.check_and_process(iaas_type,iaas_properties)
        CommandAndControl.check_and_process_iaas_properties(iaas_type,iaas_properties)
      end
      
      def hash()
        iaas_properties()
      end

      def type()
        unless ret = @target_instance.get_field?(:iaas_type)
          Log.error("Expected that :iaas_type has a value")
        end
        ret && ret.to_sym
      end

      def supports_create_image?()
        [:ec2].include?(type())
      end
     private
      def iaas_properties()
        @iaas_properties ||= @target_instance.get_field?(:iaas_properties)||{}
      end
    end
  end
end

