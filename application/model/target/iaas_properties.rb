module DTK
  class Target
    class IAASProperties
      attr_reader :name
      # IAASProperties.new will be called with 
      #  :name and :iaas_properties, or with
      # :target_instance
      def initialize(hash_args)
        @name = hash_args[:name]
        @iaas_properties = hash_args[:iaas_properties]
        @target_instance = hash_args[:target_instance]
      end

      def properties()
        iaas_properties()        
      end

      
      def self.sanitize!(iaas_properties)
        iaas_properties.reject!{|k,v|not SanitizedProperties.include?(k)}
      end
      SanitizedProperties = [:region,:keypair,:security_group,:security_group_set,:subnet_id]

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

      def iaas_properties()
        @iaas_properties ||= (@target_instance && @target_instance.get_field?(:iaas_properties))||{}
      end

      def self.equal?(i2)
        case type()
          when :ec2 then Ec2.equal?(i2)
          else raise Error.new("Unexpected iaas_properties type (#{type})")
        end
      end
      module Ec2
        def self.equal?(i2)
          i2.type == :ec2 and
            iaas_properties[:region] == i2.iaas_properties[:region]
          end
      end
    end
  end
end

