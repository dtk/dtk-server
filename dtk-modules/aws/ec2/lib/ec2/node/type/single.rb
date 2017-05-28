module DTKModule
  class Ec2::Node
    module Type
      class Single < Ec2::Node

        def discover
          dynamic_attributes(fail_on_terminate_state: true)
        end
        
        def converge_managed
          nil_addresses = false
          instance_info = 
            if attributes.value?(:instance_id)
              start_instance
            else
              create_instance
            end
          
          instance_info.fail_on_terminate_state
          OutputSettings.dynamic_attributes(instance_info, admin_state: :powered_on)
        end

        def start
          instance_info = nil
          if attributes.value?(:instance_id)
            instance_info = start_instance
            instance_info.fail_on_terminate_state
          end
          OutputSettings.dynamic_attributes(instance_info, admin_state: :powered_on)
        end

        def stop
          instance_info = nil
          if attributes.value?(:instance_id)
            instance_info = stop_instance
            instance_info.fail_on_terminate_state
          end
          OutputSettings.dynamic_attributes(instance_info, admin_state: :powered_off)
        end

        def terminate
          # no op if no instance_id -> set instance_info to nil
          instance_info = (attributes.value?(:instance_id) && aws_api_operation(:terminate).terminate_instance)
          OutputSettings.dynamic_attributes(instance_info, with_nil_address_attributes: true)
        end

        private
        
        # opts can have keys:
        #   :fail_on_terminate_state
        def dynamic_attributes(opts = {})
          instance_info =  aws_api_operation(:get).describe_instance
          instance_info.fail_on_terminate_state if opts[:fail_on_terminate_state]
          OutputSettings.dynamic_attributes(instance_info)
        end
        
        # Returns InstanceInfo object
        def create_instance
          fail DTK::Error::Usage, "Attribute 'admin_state' cannot be set to powered_off if node not created" if admin_state_powered_off?
          aws_api_operation(:create).create_instance
        end
        
        # Returns InstanceInfo object
        def describe_instance
          aws_api_operation(:get).describe_instance
        end
        
        # Returns InstanceInfo object
        def stop_instance
          aws_api_operation(:stop).stop_instance
        end
        
        # Returns InstanceInfo object
        def start_instance
          instance_info = aws_api_operation(:start).start_instance
          if instance_info.in_a_stop_state?
            fail DTK::Error::Usage, "Ec2 instance '#{instance_info.instance_id}' cannot be started"
          end
          instance_info
        end

      end
        
    end
  end
end
