module DTKModule
  module Ec2
    # Class Node is for single nodes and node groups
    class Node < Aws::Stdlib::Resource
      require_relative('node/type')
      require_relative('node/aws_api')
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

      attr_reader :client, :name, :attributes

      def dynamic_attributes
        fail "The method 'dynamic_attributes' should be overwritten for concrete class '#{self.class}'"
      end

      def aws_client_class
        ::Aws::EC2::Client
      end

      # TODO: better unify was_stdlib which uses aws_api_operation
      def aws_operation_class(operation_type)
        AwsApi::Operation.operation_class(operation_type)
      end
      def aws_operation(operation_type)
        aws_operation_class(operation_type).new(client, attributes)
      end

      def admin_state_powered_off?
        attributes.value?(OutputSettings::ADMIN_STATE_ATTRIBUTE) == OutputSettings.admin_state_value(:powered_off)
      end
        
    end
  end
end
