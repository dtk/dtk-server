module DTKModule
  class  Ec2::Node
    OperationBase = Aws::Stdlib::Resource::Operation
    class Operation < OperationBase
      require_relative('operation/wait_conditions')
      # wait_condition must be before below
      OPERATIONS = [:create, :get, :start, :stop, :terminate, :iam_instance_profile]
      OPERATIONS.each { |operation_name| require_relative("operation/#{operation_name}") }

      include WaitConditions::Mixin
      extend WaitConditions::ClassMixin

      private

      # TODO: convert to use Aws::Stdlib::Resource::ClassMethod
      def self.describe_instances(client, instance_ids)
        Get.describe_instances(client, instance_ids)
      end
      def describe_instances(instance_ids)
        self.class.describe_instances(client, instance_ids)
      end

      def self.resource_class
        Ec2::Node
      end

      def operation_name
        underscore(self.class.to_s)
      end


    end
  end
end
