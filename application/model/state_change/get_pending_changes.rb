#TODO: this file naem somewhat of a misnomer; both pending changes but also converging a 'region' such as asssembly, node group, target ..
module DTK; class StateChange

  class Assembly < self
    #TODO: need to refine how this interfacts with existing state changes
    #right now it just generates ruby objects and does not check existing state change objects
    def self.component_state_changes(assembly_idh,component_type=nil)
      filter = [:and, [:eq, :assembly_id, assembly_idh.get_id()]]
      if (component_type == :smoketest)
        filter << [:eq, :basic_type, "smoketest"]
      else
        filter << [:neq, :basic_type, "smoketest"]
      end
      sp_hash = {
        :cols => Component::pending_changes_cols,
        :filter => filter
      }
      state_change_mh = assembly_idh.createMH(:state_change)
      changes = get_objs(assembly_idh.createMH(:component),sp_hash).map do |cmp|
        node = cmp.delete(:node)
        hash = {
          :type => "converge_component",
          :component => cmp,
          :node => node
        }
        create_stub(state_change_mh,hash)
      end
      ##group by node id
      ndx_ret = Hash.new
      changes.each do |sc|
        node_id = sc[:node][:id]
        (ndx_ret[node_id] ||= Array.new) << sc
      end
      ndx_ret.values
    end

    #no generate option needed for node state changes
    def self.node_state_changes(assembly_idh,target_idh)
      changes = Array.new
      sp_hash = {
        :cols => [:id,:display_name,:group_id],
        :filter => [:eq, :assembly_id, assembly_idh.get_id()]
      }
      assembly_nodes = get_objs(assembly_idh.createMH(:node),sp_hash)
      return changes if assembly_nodes.empty?

      added_state_change_filters = [[:oneof, :node_id, assembly_nodes.map{|r|r[:id]}]]
      target_mh = target_idh.createMH()
      last_level = pending_create_node(target_mh,[target_idh],:added_filters => added_state_change_filters)
      state_change_mh = target_mh.create_childMH(:state_change)
      while not last_level.empty?
        changes += last_level
        last_level = pending_create_node(state_change_mh,last_level.map{|obj|obj.id_handle()},:added_filters => added_state_change_filters)
      end
      ##group by node id (and using fact that each wil be unique id)
      changes.map{|ch|[ch]}
    end
  end

  class NodeCentric < self
    #finds all node-centric components associated with the set of nodes meeting filter
    #TODO: now just using components on node groups, not node-centric components on individual nodes
    def self.component_state_changes(mh,nodes)
      ret = Array.new
      node_filter = Node::Filter::NodeList.new(nodes.map{|n|n.id_handle()})
      #find node to node_group mapping
      node_to_ng = NodeGroup.get_node_groups_containing_nodes(mh,node_filter)
      if node_to_ng.empty?
        return ret
      end

      #find components associated with each node group      
      ng_ndx = Hash.new
      node_to_ng.each_value{|h|h.each{|ng_id,ng|ng_ndx[ng_id] = true}}
      sp_hash = {
        :cols => [:id,:display_name,:components_for_pending_changes],
        :filter => [:oneof, :id, ng_ndx.keys]
      }
      ng_mh = mh.createMH(:node)
      ng_cmps = get_objs(ng_mh,sp_hash)
      if ng_cmps.empty?
        return ret
      end

      pp [:ng_cmps,ng_cmps]
      raise "got here"
=begin
      state_change_mh = assembly_idh.createMH(:state_change)
      changes = get_objs(assembly_idh.createMH(:component),sp_hash).map do |cmp|
        node = cmp.delete(:node)
        hash = {
          :type => "converge_component",
          :component => cmp,
          :node => node
        }
        create_stub(state_change_mh,hash)
      end
      ##group by node id
      ndx_ret = Hash.new
      changes.each do |sc|
        node_id = sc[:node][:id]
        (ndx_ret[node_id] ||= Array.new) << sc
      end
      ndx_ret.values
=end
    end
  end

#TODO: may convert to form above
  module GetPendingChangesClassMixin
    def get_ndx_node_config_changes(target_idh)
      #TODO: there is probably more efficient info to get; this provides too much
      changes = flat_list_pending_changes(target_idh)
      #TODO: stub
      changes.inject({}) do |h,r|
        node_id = r[:node][:id]
        h.merge(node_id => {:state => :changes, :detail => {}})
      end
    end

    def node_config_change__no_changes()
      {:state => :no_changes}
    end

    def flat_list_pending_changes(target_idh,opts={})
      target_mh = target_idh.createMH()
      last_level = pending_changes_one_level_raw(target_mh,[target_idh],opts)
      ret = Array.new
      state_change_mh = target_mh.create_childMH(:state_change)
      while not last_level.empty?
        ret += last_level
        last_level = pending_changes_one_level_raw(state_change_mh,last_level.map{|obj|obj.id_handle()},opts)
      end
      remove_dups_and_proc_related_components(ret)
    end

    def pending_changes_one_level_raw(parent_mh,idh_list,opts={})
      pending_create_node(parent_mh,idh_list,opts) + 
        pending_changed_component(parent_mh,idh_list,opts) +
        pending_changed_attribute(parent_mh,idh_list,opts)
    end

    def pending_create_node(parent_mh,idh_list,opts={})
      parent_field_name = DB.parent_field(parent_mh[:model_name],:state_change)
      filter = 
        [
         :and,
         [:oneof, parent_field_name,idh_list.map{|idh|idh.get_id()}],
         [:eq, :type, "create_node"],
         [:eq, :status, "pending"]]
      filter += opts[:added_filters] if opts[:added_filters]

      sp_hash = {
        :filter => filter,
        :cols => [:id,:relative_order,:type,:created_node,parent_field_name,:state_change_id,:node_id].uniq
      }
      state_change_mh = parent_mh.createMH(:state_change)
      get_objs(state_change_mh,sp_hash)
    end

    def pending_changed_component(parent_mh,idh_list,opts={})
      parent_field_name = DB.parent_field(parent_mh[:model_name],:state_change)
      sp_hash = {
        :filter => [:and,
                    [:oneof, parent_field_name,idh_list.map{|idh|idh.get_id()}],
                    [:oneof, :type, ["install_component", "update_implementation","converge_component"]],
                    [:eq, :status, "pending"]],
        :columns => [:id, :relative_order,:type,:changed_component,parent_field_name,:state_change_id].uniq
      }
      state_change_mh = parent_mh.createMH(:state_change)
      sc_with_direct_cmps = get_objs(state_change_mh,sp_hash)
      add_related_components(sc_with_direct_cmps)
    end

    def pending_changed_attribute(parent_mh,idh_list,opts={})
      parent_field_name = DB.parent_field(parent_mh[:model_name],:state_change)
      sp_hash = {
        :filter => [:and,
                    [:oneof, parent_field_name,idh_list.map{|idh|idh.get_id()}],
                    [:eq, :type, "setting"],
                    [:eq, :status, "pending"]],
        :columns => [:id, :relative_order,:type,:changed_attribute,parent_field_name,:state_change_id].uniq
      }      
      state_change_mh = parent_mh.createMH(:state_change)
      sc_with_direct_cmps = get_objs(state_change_mh,sp_hash)
      add_related_components(sc_with_direct_cmps)
    end

    def add_related_components(sc_with_direct_cmps)
      component_index = Hash.new
      sc_with_direct_cmps.each do |sc|
        cmp_id = sc[:component][:id]
        unless component_index[cmp_id]
          component_index[cmp_id] = sc
        else
          if sc[:type] == "install_component" 
            component_index[cmp_id] = sc
          end
        end
      end

      cols = [:id,:display_name,:basic_type,:external_ref,:node_node_id,:only_one_per_node,:extended_base,:implementation_id]
      cmps_in_sc = component_index.values.map{|sc|sc[:component]}
      related_cmps = Component.get_component_instances_related_by_mixins(cmps_in_sc,cols)
      #TODO: assumption that cmps only appear once in sc_with_direct_cmps

      sc_with_related_cmps = Array.new
      related_cmps.map do |cmp|
        cmp[:assoc_component_ids].each do |cmp_id|
          related_sc = component_index[cmp_id].merge(:component => cmp)
          sc_with_related_cmps << related_sc
        end
      end

      sc_with_direct_cmps + sc_with_related_cmps
    end

    def remove_dups_and_proc_related_components(state_changes)
      indexed_ret = Hash.new
      #remove duplicates wrt component and process linked_ids
      state_changes.each do |sc|
        if sc[:type] == "create_node"
          indexed_ret[sc[:node][:id]] = augment_with_linked_id(sc,sc[:id])
          #TODO: ordering may do thsis anyway, but do we explicitly want to make sure if both setting adn isnatll use install as type
        elsif ["setting","install_component","update_implementation","converge_component"].include?(sc[:type])
          indexed_ret[sc[:component][:id]] = augment_with_linked_id(indexed_ret[sc[:component][:id]] || sc.reject{|k,v|[:attribute].include?(k)},sc[:id])
        else
          Log.error("unexpected type #{sc[:type]}; ignoring")
        end
      end
      indexed_ret.values
    end

   private
    #linked ids is link to relevant stage_change objects
    def augment_with_linked_id(state_change,id)
      if linked = state_change[:linked_ids]
        linked.include?(id) ? state_change : state_change.merge(:linked_ids => linked + [id])
      else
        state_change.merge(:linked_ids => [id])
      end
    end
  end
end; end

