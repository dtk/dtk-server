module XYZ
  class NodeGroup < Node
    r8_nested_require('node_group','clone')
    include CloneMixin

    def self.create_instance(target_idh,display_name,opts={})
      create_row = {
        :ref => display_name,
        :display_name => display_name,
        :datacenter_datacenter_id => target_idh.get_id(),
        :type => "node_group_instance"
      }
      ng_mh = target_idh.create_childMH(:node)
      new_ng_idh = create_from_row(ng_mh,create_row)
      if opts[:spans_target]
        NodeGroupRelation.create_to_span_target?(new_ng_idh,target_idh,:donot_check_if_exists => true)
      end
      new_ng_idh
    end

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
      new_cmp = clone_into(component_template_idh.create_object(),override_attrs,clone_opts)
      new_cmp.id_handle()
    end

    def delete_component(component_idh)
      #first check that component_idh belongs to this insatnce
      sp_hash = {
        :cols => [:id, :display_name],
        :filter => [:and, [:eq, :id, component_idh.get_id()], [:eq, :node_node_id, id()]]
      }
      unless Model.get_obj(model_handle(:component),sp_hash)
        raise ErrorIdInvalid.new(component_idh.get_id(),:component)
      end
      Model.delete_instance(component_idh)
    end

    #TODO: change to having node group having explicit links or using a saved search
    def get_node_members()
      sp_hash = {
        :cols => [:node_members]
      }
      rows = get_objs(sp_hash)
      if target_idh = NodeGroupRelation.spans_target?(rows.map{|r|r[:node_group_relation]})
        target_idh.create_object().get_node_members()
      else
        rows.map{|r|r[:node_member]}
      end
    end

    #for each member of node_idhs, returns the node groups it beongs to
    # for is {node_id => {ng_id1 => ng1,..}
    #TODO: this can potentially be expensive to compute without enhancements
    def self.get_node_groups_containing_nodes(node_idhs)
      ng_mh = node_idhs.first.createMH(:node)
      node_ids = node_idhs.map{|n|n.get_id()}
      #TODO: more efficient to filter on sql side
      sp_hash = {
        :cols => [:id,:group_id, :display_name,:node_members]
      }
      node_to_ng = Hash.new
      target_nodes = Hash.new
      get_objs(ng_mh,sp_hash).each do |r|
        node_group = r.hash_subset(:id,:group_id,:display_name)
        if target_idh = r[:node_group_relation].spans_target?
          target_id = target_idh.get_id()
          unless target_nodes[target_id] 
            target_nodes[target_id] = (target_idh.create_object().get_node_members().map{|n|n[:id]} & node_ids)
            target_nodes[target_id].each do |n_id|
              (node_to_ng[n_id] ||= Hash.new)[node_group[:id]] ||= node_group
            end
          end
        elsif node_ids.include?(r[:node_member][:id])
          (node_to_ng[r[:node_member][:id]] ||= Hash.new)[node_group[:id]] ||= node_group
        end
      end
      node_to_ng
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

