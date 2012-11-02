module XYZ
  class NodeGroup < Node
    r8_nested_require('node_group','clone')
    include CloneMixin
    def self.list(model_handle)
      sp_hash = {
        :cols => [:id, :display_name, :description],
        :filter => [:eq, :type, "node_group_instance"]
      }
      get_objs(model_handle,sp_hash)
    end

    def add_component(component_template_idh)
      override_attrs = Hash.new
      clone_opts = {:no_post_copy_hook => true,:ret_new_obj_with_cols => [:id,:display_name]}
      clone_into(component_template_idh.create_object(),override_attrs,clone_opts)
    end

    def delete_component(component_idh)
      Model.delete_instance(component_idh)
    end

    def node_members()
      sp_hash = {
        :cols => [:node_member]
      }
      get_objs(sp_hash).map{|r|r[:node_member]}
    end

    def self.check_valid_id(model_handle,id)
      filter = 
        [:and,
         [:eq, :id, id],
         [:eq, :type, "node_group_instance"],
         [:neq, :datacenter_datacenter_id, nil]]
      check_valid_id_helper(model_handle,id,filter)
    end

    def self.name_to_id(model_handle,name)
      sp_hash =  {
        :cols => [:id],
           :filter => [:and,
                       [:eq, :display_name, name],
                       [:eq, :type, "node_group_instance"],
                       [:neq, :datacenter_datacenter_id, nil]]
      }
      name_to_id_helper(model_handle,name,sp_hash)
    end

    def get_canonical_template_node()
      get_objs(:cols => [:canonical_template_node]).map{|r|r[:template_node]}.first
    end

    def clone_and_add_template_node(template_node)
      #clone node into node group's target 
      target_idh = id_handle.get_top_container_id_handle(:target,:auth_info_from_self => true)
      target = target_idh.create_object()
      cloned_node_id = target.add_item(template_node.id_handle)
      target.update_ui_for_new_item(cloned_node_id)

      #add node group relationship
      cloned_node = model_handle(:node).createIDH(:id => cloned_node_id).create_object()
      add_member(cloned_node,target_idh,:dont_check_redundancy => true)
      cloned_node.id_handle
    end

    def add_member(instance_node,target_idh,opts={})
      node_id = instance_node[:id]
      ng_id = self[:id]
      #check for redundancy
      unless opts[:dont_check_redundancy]
        sp_hash = {
          :cols => [:id],
          :filter => [:and, [:eq, :node_id, node_id], [:eq, :node_group_id, ng_id]]
        }
        redundant_links = Model.get_objs(model_handle(:node_group_relation),sp_hash)
        raise Error.new("Node already member of node group") unless redundant_links.empty?
      end
      #create the node_group_relation item to indicate node group membership
      create_row = {
        :ref => "n#{node_id.to_s}-ng#{ng_id.to_s}",
        :node_id => node_id,
        :node_group_id => ng_id,
        :datacenter_datacenter_id => target_idh.get_id
      }
      Model.create_from_rows(model_handle(:node_group_relation),[create_row])

      #clone the components and links associated with node group to teh node
      clone_into_node(instance_node)
    end

    def delete()
      #TODO: stub
      Model.delete_instance(id_handle())
    end
    def destroy_and_delete
      delete()
    end
    private
    #TODO: can we avoid explicitly placing this here?
     def self.db_rel()
       Node.db_rel()
     end
  end
end

