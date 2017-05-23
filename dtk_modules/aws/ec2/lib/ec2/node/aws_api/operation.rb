module DTKModule
  module Ec2::Node::AwsApi
    class Operation
      require_relative('operation/wait_conditions')
      # wait_condition must be before operation

      OPERATIONS = [:create, :get, :start, :stop, :terminate]
      OPERATIONS.each { |operation_name| require_relative("operation/#{operation_name}") }

      include WaitConditions::Mixin
      extend WaitConditions::ClassMixin

      def initialize(client, attributes)
        @client = client
        @params = check_and_return_input_settings(attributes)
      end

      private

      attr_reader :client, :params

      def self.describe_instances(client, instance_ids)
        Get.describe_instances(client, instance_ids)
      end
      def describe_instances(instance_ids)
        self.class.describe_instances(client, instance_ids)
      end

      def check_and_return_input_settings(attributes)
        input_settings = input_settings_class.settings_from_attributes(attributes)
        missing_attributes = input_settings_class.required.select { |attr| input_settings[attr].nil? }
        raise_missing_attributes(missing_attributes) unless missing_attributes.empty?
        input_settings
      end
      
      def input_settings_class
         self.class::InputSettings
      end
      
      def raise_missing_attributes(missing_attributes)
        error_msg = 
          if missing_attributes.size > 1
            "The following attributes are needed to #{operation_name} an EC2 instance, but are missing: #{missing_attributes.join(', ')}"
          else
            "The attribute '#{missing_attributes.first}' is missing, but needed to #{operation_name} an EC2 instance"
          end
        fail DTK::Error::Usage.new(error_msg)
      end

      def operation_name
        self.class.to_s.split('::').last.downcase
      end

      def self.operation_class(operation_name)
        const_get operation_name.to_s.capitalize
      end

    end
  end
end
