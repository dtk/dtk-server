module DTKModule
  module Ec2::Node::AwsApi
    class Operation
      class Get < self
        class InputSettings < DTK::Settings
          REQUIRED = [:instance_id]
        end

        # returns an InstanceInfo object
        def describe_instance
          instance_info_array = describe_instances([params.instance_id])
          case instance_info_array.size
          when 1
            instance_info_array.first
          when 0
            fail "Unexpected that no instances returned for call AwsApi#describe_instance(#{instance_id})" 
          else
            fail "Unexpected that multiple instances returned for call AwsApi#describe_instance(#{instance_id})" 
          end
        end
        

        # returns an array of InstanceInfo objects
        def self.describe_instances(client, instance_ids)
          ret = []
          result = client.describe_instances(instance_ids: instance_ids)
          result.reservations.each do |reservation| 
            reservation.instances.each { |aws_ec2_types_instance| ret << InstanceInfo.new(aws_ec2_types_instance) }
          end
          ret
        end

      end
    end
  end
end
