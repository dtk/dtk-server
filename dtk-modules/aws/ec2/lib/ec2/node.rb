module DTKModule
  module Ec2
    # Class Node is for single nodes and node groups
    class Node < Aws::Stdlib::Resource
      require_relative('node/type')
      require_relative('node/operation')
      require_relative('node/map_from_aws_attributes')
      require_relative('node/instance_info')
      require_relative('node/output_settings')

      # returns dynamic_attributes encoded in OutputSettings object
      def self.converge(credentials_handle, name, attributes)
        new(credentials_handle, name, attributes).converge
      end
      def converge
        if attributes.value?(:discovered)
          discover
        else
          create_instance_output_settings = OutputSettings.set_create_instance_attributes!(attributes)
          converge_managed.merge(create_instance_output_settings)
        end
      end

      # returns dynamic_attributes encoded in OutputSettings object
      def self.delete(credentials_handle, name, attributes)
        new(credentials_handle, name, attributes).delete
      end
      def delete
        if attributes.value?(:discovered)
          # no op; just return dynamic_attributes
          dynamic_attributes
        else
          terminate
        end
      end

      # returns dynamic_attributes encoded in OutputSettings object
      def self.start(credentials_handle, name, attributes)
        new(credentials_handle, name, attributes).start
      end

      # returns dynamic_attributes encoded in OutputSettings object
      def self.stop(credentials_handle, name, attributes)
        new(credentials_handle, name, attributes).stop
      end

      private

      attr_reader :name

      def dynamic_attributes
        fail "The method 'dynamic_attributes' should be overwritten for concrete class '#{self.class}'"
      end

      def aws_client_class
        ::Aws::EC2::Client
      end

      def admin_state_powered_off?
        attributes.value?(OutputSettings::ADMIN_STATE_ATTRIBUTE) == OutputSettings.admin_state_value(:powered_off)
      end
        
    end
  end
end
