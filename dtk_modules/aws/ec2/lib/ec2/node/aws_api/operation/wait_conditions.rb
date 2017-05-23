module DTKModule
  module Ec2::Node::AwsApi
    class Operation
      module WaitConditions
        module Mixin
          def conditions_met_all_instances?(instance_info_array, &wait_conditions)
            WaitConditions.conditions_met_all_instances?(instance_info_array, &wait_conditions)
          end

          def wait_until(operation, instance_ids, opts = {}, &wait_conditions)
            WaitConditions.wait_until(client, operation, instance_ids, opts, &wait_conditions)
          end

          private

          def wait_for_create(instance_ids)
            wait_for_create_or_start(:create, instance_ids)
          end
          
          def wait_for_start(instance_ids)
            wait_for_create_or_start(:start, instance_ids)
          end
          
          CREATE_START_WAIT_OPTIONS = { max_attempts: 20, delay: 5 }
          def wait_for_create_or_start(operation, instance_ids)
            wait_until(operation, instance_ids, CREATE_START_WAIT_OPTIONS) do |instance_info|
              instance_info.in_a_stop_state? or instance_info.in_a_terminate_state? or # dont wait if terminate or stop state
                instance_has_needed_address?(instance_info)
            end
          end

          def instance_has_needed_address?(instance_info)
            if params.enable_public_ip_in_subnet
              instance_info.has_public_dns_name?
            else
              instance_info.has_private_ip_address?
            end
          end

        end

        module ClassMixin
          def conditions_met_all_instances?(instance_info_array, &wait_conditions)
            WaitConditions.conditions_met_all_instances?(instance_info_array, &wait_conditions)
          end

          def wait_until(client,operation, instance_ids, opts = {}, &wait_conditions)
            WaitConditions.wait_until(client, operation, instance_ids, opts, &wait_conditions)
          end
        end

        def self.conditions_met_all_instances?(instance_info_array, &wait_conditions)
          # retutuns true all if all match
          ! instance_info_array.find { |instance_info| !conditions_met?(instance_info, &wait_conditions) }
        end
        
        WAIT_DEFAULT_MAX_ATTEMPTS = 20
        WAIT_DEFAULT_DELAY = 5
        
        # opts can have keys:
        #   :max_attempts
        #   :delay
        # returns an InstanceInfo array of state that matched or throws error if gets to max_attempts
        def self.wait_until(client, operation, instance_ids, opts = {}, &wait_conditions)
          max_attempts = opts[:max_attempts] || WAIT_DEFAULT_MAX_ATTEMPTS
          delay        = opts[:delay] || WAIT_DEFAULT_DELAY
          attempts = 0
          instance_info_array = nil
          while attempts < max_attempts
            instance_info_array = Operation.describe_instances(client, instance_ids)
            if conditions_met_all_instances?(instance_info_array, &wait_conditions)
              return instance_info_array
            else
              attempts += 1
              sleep delay
            end
          end
          
          # if reach here conditions do not match so fail
          raise_error_failed_wait_conditions(instance_info_array, operation, &wait_conditions)
        end

        private

        def self.conditions_met?(instance_info, &wait_conditions)
          wait_conditions.call(instance_info)
        end

        def self.raise_error_failed_wait_conditions(instance_info_array, operation, &wait_conditions)
          bad_instance_ids = instance_info_array.select { |instance_info| !wait_conditions.call(instance_info) }.map(&:instance_id)
          fail DTK::Error::Usage, failed_exit_condition_error_message(bad_instance_ids, operation) unless bad_instance_ids.empty?
          instance_info_array # this is for corner case where on last try meet conditions
        end

        def self.failed_exit_condition_error_message(bad_instance_ids, operation)
          if bad_instance_ids.size == 1
            "Failed to meet wait until conditions for operation '#{operation}' on ec2 instance '#{bad_instance_ids.first}'"
          else # bad_instance_ids.size > 1
            "Failed to meet wait until conditions for operation '#{operation}' on ec2 instance ids: #{bad_instance_ids.jon(', ')}"
          end
        end

      end
    end
  end
end

