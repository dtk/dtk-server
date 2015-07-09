module DTK
  class Target
    class IAASProperties
      r8_nested_require('iaas_properties', 'ec2')
      attr_reader :name
      # IAASProperties.new will be called with
      #  :name and :iaas_properties, or with
      # :target_instance
      def initialize(hash_args)
        @name = hash_args[:name]
        @iaas_properties = hash_args[:iaas_properties]
        @target_instance = hash_args[:target_instance]
      end

      def properties
        iaas_properties()
      end

      def self.sanitize_and_modify_for_print_form!(type, iaas_properties)
        unless type.nil? || iaas_properties.nil?
          case type.to_sym
           when :ec2
            Ec2.sanitize!(iaas_properties)
            Ec2.modify_for_print_form!(iaas_properties)
          end
        end
      end

      def self.more_specific_type?(type, iaas_properties)
        unless type.nil? || iaas_properties.nil?
          case type.to_sym
          when :ec2
            Ec2.more_specific_type?(iaas_properties)
          end
        end
      end

      def self.check(iaas_type, iaas_properties, opts = {})
        CommandAndControl.check_iaas_properties(iaas_type, iaas_properties, opts)
      end

      def hash
        iaas_properties()
      end

      def type
        unless ret = @target_instance.get_field?(:iaas_type)
          Log.error('Expected that :iaas_type has a value')
        end
        ret && ret.to_sym
      end

      def supports_create_image?
        [:ec2].include?(type())
      end

      def iaas_properties
        @iaas_properties ||= (@target_instance && @target_instance.get_field?(:iaas_properties)) || {}
      end

      def self.equal?(i2)
        case type()
          when :ec2 then Ec2.equal?(i2)
          else fail Error.new("Unexpected iaas_properties type (#{type})")
        end
      end
    end
  end
end
