=begin
There might be anumber of ways to encode this; such as actually adding to schema; one direction looking towards is having effectively foreign
keys where for example the linux user can point to  a linux user table.
In approach below teher wil be a numeric key genearted which is a handle on object; sometimes an attribute may be key, but not sure always
=end
module DTK; class Component
  class Instance
    class Interpreted < self
      # idempotent; if reassert twice with same valeus it does not change
      # also if assert with less keys; it delete those ones omitted
      def self.create_or_update?(node,component_type,attr_hash)
        component_type = component_type.to_s
        raise ErrorUsage.new("Not able to find 'key_name' in provided data, 'key_name' is required field") unless attr_hash[:key_name]
        internal_hash = HashForm.convert_to_internal(attr_hash[:key_name], component_type,node.id, attr_hash)
        update_from_hash_assignments(node.id_handle(),internal_hash)
        get_component(node,attr_hash[:key_name],component_type).id_handle()
      end

      def self.delete(node, component_type, attr_hash)
        raise ErrorUsage.new("Not able to find 'key_name' in provided data, 'key_name' is required field") unless attr_hash[:key_name]
        cmp = get_component(node,attr_hash[:key_name], component_type.to_s)

        Model.delete_instance(cmp.id_handle()) if cmp
      end

      def self.get_attribute_hash(node, component_id)
        sp_hash = {
          :cols => [:id,:display_name,:group_id,:value_asserted],
          :filter => [:and, [:eq,:component_component_id, component_id], [:neq,:display_name, 'key_content']]
        }
        get_objs(node.model_handle(:attribute),sp_hash).inject(AttributeHash.new) do |h,r|
          h.merge(r[:display_name] => r[:value_asserted])
        end
      end

      def self.find_candidates(assembly, system_user, pub_name, agent_action, target_nodes = [])
        results = list_ssh_access(assembly)

        nodes = target_nodes.empty? ? assembly.get_nodes(:id,:display_name,:external_ref) : target_nodes

        #
        # if :grant_access  than rejected_bool ==> false (keep if not matched)
        # if :revoke_access than rejected_bool ==> true  (keep only if matched)
        #
        rejected_bool = (agent_action.to_sym == :revoke_access)

        nodes.reject! do |node|
          is_rejected = rejected_bool
          results.each do |r|
            if node[:display_name] == r[:node_name]
              if r[:attributes]["linux_user"].eql?(system_user) && r[:attributes]["key_name"].eql?(pub_name)
                is_rejected = !rejected_bool
              end
            end
          end
          is_rejected
        end
        
        nodes
      end



      def self.list_ssh_access(assembly, component_type = :authorized_ssh_public_key)
        nodes = assembly.get_nodes()

        result_array = []

        nodes.each do |node|
          sp_hash = {
            :cols   => [:id, :display_name],
            :filter => [:and,[:eq,:node_node_id,node.id],[:eq, :component_type, component_type.to_s]]
          }
        
          components = get_objs(assembly.model_handle(:component_instance),sp_hash)

          components.each do |cmp|
            result_array << { :node_name => node.display_name, :attributes => get_attribute_hash(node, cmp.id) }
          end
        end

        result_array
      end

     private
      # TODO: probably better if this returns a Component::Instance:Interpreted object
      def self.get_component(node,component_name,component_type)
        sp_hash = {
          :cols => [:id,:display_name,:group_id],
          :filter => [:and,[:eq,:display_name,component_name],[:eq,:node_node_id,node.id()],[:eq, :component_type, component_type.to_s]]
        }
        get_obj(node.model_handle(:component_instance),sp_hash)
      end

      class AttributeHash < Hash
      end
      class HashForm 
        def self.convert_to_internal(component_name, component_type, node_id,attr_hash)
          {
            :component => {
              "#{component_type}-#{component_name}" => {
                :display_name => component_name,
                :component_type => component_type,
                :type => 'action_effects', #TODO: might make this instead 'interpreted'
                :attribute => attributes(attr_hash, node_id)
              }
            }
          }
        end
       private
        def self.attributes(input_attr_hash, node_id)
          # what this does is to capture that what is in this is the complete set of attribute 
          results = input_attr_hash.inject(DBUpdateHash.new().mark_as_complete()) do |h,(k,v)|
            attr_fields = {
              :display_name => k.to_s,
              :value_asserted => v.to_s,
              :data_type => 'string',
              :semantic_data_type => 'string'
            }

            h.merge(k => attr_fields)
          end

          results
        end
      end
    end
  end
end; end