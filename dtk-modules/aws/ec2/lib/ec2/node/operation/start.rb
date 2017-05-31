module DTKModule
  class Ec2::Node::Operation 
    class Start < self
      class InputSettings < DTK::Settings
        OPTIONAL = [:instance_id, :enable_public_ip_in_subnet, :iam_instance_profile]
      end

      # returns InstanceInfo
      def start_instance
        unless instance_id = params.instance_id
          fail "Unexpected that params.instance_id is nil"
        end
        start_instances([instance_id]).first
      end

      # returns InstanceInfo array
      def start_instances(instance_ids)
        IamInstanceProfile.set_iam_instance_profiles(self, instance_ids, params.iam_instance_profile)

        # If all instances are already in start state dont call client.start_instances
        unless conditions_met_all_instances?(describe_instances(instance_ids)) { |instance_info| instance_info.in_a_run_state? }
          client.start_instances(instance_ids: instance_ids)
        end
        wait_for_start(instance_ids)
      end

    end
  end
end
