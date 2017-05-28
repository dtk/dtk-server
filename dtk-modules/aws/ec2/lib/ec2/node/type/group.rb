module DTKModule
  class Ec2::Node
    module Type
      class Group < Ec2::Node
        require_relative('group/converge')
        require_relative('group/instance_id_mixin')

        extend InstanceIdMixin
        include InstanceIdMixin

        def converge_managed
          start if admin_state_powered_off?
          
          # converge_info is of type Converge::Output; each of its elements are of type InstanceInfo array
          converge_info = Converge.converge_managed(self, cardinalty, existing_instances)
          
          alive_dynamic_attributes_array      = updated_dynamic_attributes_array(converge_info.alive)
          terminated_dynamic_attributes_array = updated_dynamic_attributes_array(converge_info.terminated, with_nil_address_attributes: true)
          { instances: alive_dynamic_attributes_array + terminated_dynamic_attributes_array, admin_state: :powered_on }
        end

        def start
          instances = existing_instances()
          instance_info_array = 
            if instances.size > 0
              aws_api_operation(:start).start_instances(instance_ids(instances))
            end
          { instances: updated_dynamic_attributes_array(instance_info_array), admin_state: :powered_on }
        end

        def stop
          instances = existing_instances()
          instance_info_array = 
            if instances.size > 0
              aws_api_operation(:stop).stop_instances(instance_ids(instances))
            end
          { instances: updated_dynamic_attributes_array(instance_info_array), admin_state: :powered_off }
        end

        def terminate
          instances = existing_instances()
          instance_info_array = 
            if instances.size > 0
              terminate_instances(instance_ids(instances))
            end
          { instances: updated_dynamic_attributes_array(instance_info_array, with_nil_address_attributes: true) }
        end

        # Returns InstanceInfo array of size count
        def create_instances(count)
          fail DTK::Error::Usage, "Attribute 'admin_state' cannot be set to powered_off if node not created" if admin_state_powered_off?
          aws_api_operation(:create).create_instances(count)
        end
        
        def terminate_instances(instance_ids)
          aws_api_operation_class(:terminate).terminate_instances(client, instance_ids)
        end
        
        private

        # opts can have keys
        #   :with_nil_address_attributes
        def updated_dynamic_attributes_array(instance_info_array, opts = {})
          updated_instance_info_array = get_updated_info(instance_info_array)
          updated_instance_info_array.map { | instance_info| OutputSettings.dynamic_attributes(instance_info, opts) }
        end

        # Returns InstanceInfo object
        def get_updated_info(instances)
          # find updated values for all insatnces with instance_ids
          ndx_instances          = {} # instances indexed by array index 
          instance_id_to_index   = {}
          (instances || []).each_with_index do |instance, index|
            ndx_instances[index] = instance
            if instance_id = instance_id?(instance)
              instance_id_to_index[instance_id] = index
            end 
          end
          
          # in ndx_instances replace all instances where we get updated info
          describe_instances(instance_id_to_index.keys).each do |instance|
            index = instance_id_to_index[instance_id(instance)]
            ndx_instances[index] = instance
          end
          ndx_instances.values
        end

        # Returns InstanceInfo object
        def describe_instances(instance_ids)
          return [] if instance_ids.empty?
          aws_api_operation_class(:get).describe_instances(client, instance_ids)
        end

        def cardinalty
          attributes.value(:cardinality)
        end

        def existing_instances
          (attributes.value?(:instances) || [])
        end

      end
    end
  end
end
