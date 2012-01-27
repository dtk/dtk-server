r8_nested_require('node_group','clone')
module XYZ
  class NodeGroup < Node
    include NodeGroupClone
    def node_members()
      sp_hash = {
        :cols => [:node_member]
      }
      get_objs(sp_hash).map{|r|r[:node_member]}
    end

    def get_canonical_template_node()
      get_objs(:cols => [:canonical_template_noded]).map{|r|r[:node]}.first
    end

    def add_instance_node(instance_node,target_idh,opts={})
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
        :display_name => "n#{node_id.to_s}-ng#{ng_id.to_s}",
        :node_id => node_id,
        :node_group_id => ng_id,
        :datacenter_datacenter_id => target_idh.get_id
      }
      Model.create_from_rows(model_handle,[create_row])

      #clone the components and links associated with node group to teh node
      clone_into_node(instance_node)
    end

    def clone_and_add_template_node(template_node)
      #clone node into node group's target 
      target_idh = get_top_container_id_handle(:target,:auth_info_from_self => true)
      target = target_idh.create_object()
      cloned_node = target.add_item(template_node.id_handle)
      target.update_ui_for_new_item(cloned_node[:id])

      #add node group relationship
      add_instance_node(cloned__node,target_idh,:dont_check_redundancy => true)
      cloned_node.id_handle
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

