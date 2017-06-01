module DTKModule
  class Ec2::Node::Operation 
    class Terminate < self
      class InputSettings < DTK::Settings
        REQUIRED = [:instance_id]
      end

      def terminate_instance
        self.class.terminate_instances(client, [params.instance_id]).first
      end

      # returns InstanceInfo array
      def self.terminate_instances(client, instance_ids)
        # If already in terminate state dont call client.terminate_instance
        instance_info_array = describe_instances(client, instance_ids)
        return instance_info_array if conditions_met_all_instances?(instance_info_array, &EXIT_CONDITIONS)

        client.terminate_instances(instance_ids: instance_ids)

        wait_until(client, :terminate, instance_ids, WAIT_OPTIONS, &EXIT_CONDITIONS)
      end
      WAIT_OPTIONS = { max_attempts: 20, delay: 5 }
      EXIT_CONDITIONS = lambda { |instance_info| instance_info.in_a_terminate_state? }

    end
  end
end
