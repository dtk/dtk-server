module DTK
  class NodeGroup < Node
    r8_nested_require('node_group','clone')
    include CloneMixin

    def self.get_component_list(nodes,opts={})
      ret = opts[:add_on_to]||opts[:seed]||Array.new
      return ret if nodes.empty? 
      # find node_to_ng mapping
      node_filter = opts[:node_filter] || Node::Filter::NodeList.new(nodes.map{|n|n.id_handle()})
      node_to_ng = get_node_groups_containing_nodes(nodes.first.model_handle(:node_group),node_filter)
      node_group_ids = node_to_ng.values.map{|r|r.keys}.flatten.uniq
      sp_hash = {
        :cols => Node::Instance.component_list_fields() + [:component_list],
        :filter => [:oneof, :id, node_group_ids + nodes.map{|n|n[:id]}]
      }
      rows = get_objs(nodes.first.model_handle(),sp_hash)
      
      ndx_cmps = Hash.new
      ndx_node_ng_info = Hash.new
      rows.each do |r|
        cmp = r[:component]
        cmp_id = cmp[:id]
        ndx_cmps[cmp_id] ||= cmp
        pntr = ndx_node_ng_info[r[:id]] ||= {:node_or_ng => r.hash_subset(:id,:display_name)}
        (pntr[:component_ids] ||= Array.new) << cmp_id
      end
      # add titles to components that are non singletons
      Component::Instance.add_title_fields?(ndx_cmps.values)

      nodes.each do |node|
        # find components on the node group
        (node_to_ng[node[:id]]||{}).each_key do |ng_id|
          if node_ng_info = ndx_node_ng_info[ng_id]
            node_ng_info[:component_ids].each do |cmp_id|
              el = ndx_cmps[cmp_id].merge(
                :node => node,
                :source => {:type => "node_group", :object => node_ng_info[:node_or_ng]}
              )
              ret << el
            end
          end
        end

        # find components on the node
        ((ndx_node_ng_info[node[:id]]||{})[:component_ids]||[]).each do |cmp_id|
          el = ndx_cmps[cmp_id].merge(
            :node => node,
            :source => {:type => "node", :object => node}
          )
          ret << el
        end
      end

      ret
    end

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

    # TODO: change to having node group having explicit links or using a saved search
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

    # returns node group to node mapping for each node matching node filter
    # for is {node_id => {ng_id1 => ng1,..}
    # possible that node_id does not appear meaning that this node does not belong to any group
    # TODO: this can potentially be expensive to compute without enhancements
    def self.get_node_groups_containing_nodes(mh,node_filter)
      ng_mh = mh.createMH(:node)
      # TODO: more efficient to push node_filte into sql query
      sp_hash = {
        :cols => [:id,:group_id, :display_name,:node_members]
      }
      node_to_ng = Hash.new
      target_nodes = Hash.new
      get_objs(ng_mh,sp_hash).each do |r|
        node_group = r.hash_subset(:id,:group_id,:display_name)
        if target_idh = r[:node_group_relation].spans_target?
          target_id = target_idh.get_id()
          target_nodes[target_id] ||= node_filter.filter(target_idh.create_object().get_node_members()).map{|n|n[:id]} 
          target_nodes[target_id].each do |n_id|
            (node_to_ng[n_id] ||= Hash.new)[node_group[:id]] ||= node_group
          end
        elsif node_filter.include?(r[:node_member])
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

    def self.id_to_name(model_handle, id)
      sp_hash =  {
        :cols => [:display_name],
           :filter => [:and,
                       [:eq, :id, id],
                       [:eq, :type, "node_group_instance"],
                       [:neq, :datacenter_datacenter_id, nil]]
      }
      rows_raw = get_objs(model_handle,sp_hash)
      return rows_raw.first[:display_name]
    end

    def get_canonical_template_node()
      get_objs(:cols => [:canonical_template_node]).map{|r|r[:template_node]}.first
    end

    def clone_and_add_template_node(template_node)
      # clone node into node group's target 
      target_idh = id_handle.get_top_container_id_handle(:target,:auth_info_from_self => true)
      target = target_idh.create_object()
      cloned_node_id = target.add_item(template_node.id_handle)
      target.update_ui_for_new_item(cloned_node_id)

      # add node group relationship
      cloned_node = model_handle(:node).createIDH(:id => cloned_node_id).create_object()
      add_member(cloned_node,target_idh,:dont_check_redundancy => true)
      cloned_node.id_handle
    end

    def add_member(instance_node,target_idh,opts={})
      node_id = instance_node[:id]
      ng_id = self[:id]
      # check for redundancy
      unless opts[:dont_check_redundancy]
        sp_hash = {
          :cols => [:id],
          :filter => [:and, [:eq, :node_id, node_id], [:eq, :node_group_id, ng_id]]
        }
        redundant_links = Model.get_objs(model_handle(:node_group_relation),sp_hash)
        raise Error.new("Node already member of node group") unless redundant_links.empty?
      end
      # create the node_group_relation item to indicate node group membership
      create_row = {
        :ref => "n#{node_id.to_s}-ng#{ng_id.to_s}",
        :node_id => node_id,
        :node_group_id => ng_id,
        :datacenter_datacenter_id => target_idh.get_id
      }
      Model.create_from_rows(model_handle(:node_group_relation),[create_row])

      # clone the components and links associated with node group to teh node
      clone_into_node(instance_node)
    end

    def delete()
      Model.delete_instance(id_handle())
    end
    def destroy_and_delete
      delete()
    end
  end
end

