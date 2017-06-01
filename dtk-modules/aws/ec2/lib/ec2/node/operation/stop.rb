module DTKModule
  class Ec2::Node::Operation 
    class Stop < self
      class InputSettings < DTK::Settings
        OPTIONAL = [:instance_id]
      end

      # returns InstanceInfo
      def stop_instance
        unless instance_id = params.instance_id
          fail "Unexpected that params.instance_id is nil"
        end
        stop_instances([instance_id]).first
      end

      # returns InstanceInfo array
      def stop_instances(instance_ids)
        # If all instances are already in stop state dont call client.stop_instances
        unless conditions_met_all_instances?(describe_instances(instance_ids), &INITIAL_CHECK_CONDITIONS)
          client.stop_instances(instance_ids: instance_ids)
        end
        wait_until(:stop, instance_ids, WAIT_OPTIONS, &WAIT_EXIT_CONDITIONS)
      end
      
      INITIAL_CHECK_CONDITIONS = lambda { |instance_info| instance_info.in_a_stop_state? }

      WAIT_OPTIONS = { max_attempts: 20, delay: 5 }
      WAIT_EXIT_CONDITIONS = lambda do |instance_info|
        # wait until in stop state
        # but dont wait if in terminate state
        instance_info.in_a_stop_state? or instance_info.in_a_terminate_state? 
      end

    end
  end
end
