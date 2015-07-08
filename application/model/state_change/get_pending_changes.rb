# TODO: this file name somewhat of a misnomer; both pending changes but also converging a 'region' such as asssembly, node group, target ..
module DTK; class StateChange
  module GetPendingChangesClassMixin
    def get_ndx_node_config_changes(target_idh)
      # TODO: there is probably more efficient info to get; this provides too much
      changes = flat_list_pending_changes(target_idh)
      # TODO: stub
      changes.inject({}) do |h,r|
        node_id = r[:node][:id]
        h.merge(node_id => {state: :changes, detail: {}})
      end
    end

    def node_config_change__no_changes
      {state: :no_changes}
    end

    def flat_list_pending_changes(target_idh,opts={})
      target_mh = target_idh.createMH()
      last_level = pending_changes_one_level_raw(target_mh,[target_idh],opts)
      ret = []
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
        filter: filter,
        cols: [:id,:relative_order,:type,:created_node,parent_field_name,:state_change_id,:node_id].uniq
      }
      state_change_mh = parent_mh.createMH(:state_change)
      # using ndx_ret to remove duplicate pending changes for same node
      ndx_ret = {}
      get_objs(state_change_mh,sp_hash).each do |r|
        node_id = r[:node][:id]
        ndx_ret[node_id] ||= r
      end
      pending_scs = ndx_ret.values

      # TODO: compensating for fact that a component a node group could have state pending, but
      # no changes under it
      node_group_scs = pending_scs.select{|sc|sc[:node].is_node_group?()}
      return pending_scs if node_group_scs.empty?
      sc_ids_to_remove = find_any_without_pending_children?(node_group_scs.map{|sc|sc.id_handle()})
      #remove any sc in pending_scs that is in ndx_ng_sc_idhs but not in ndx_to_keep
      return pending_scs if sc_ids_to_remove.empty? #shortcut
     pending_scs.reject{|sc|sc_ids_to_remove.include?(sc.id)}
    end

    #returns ids for all that do not pending children 
    def find_any_without_pending_children?(sc_idhs)
      ret = []
      return ret if sc_idhs.empty?
      ndx_found = sc_idhs.inject({}){|h,sc_idh|h.merge(sc_idh.get_id() => nil)} #initially setting evrything to nil and flipping if found
      sp_hash = {
        cols: [:state_change_id],
        filter: [:and,
                 [:oneof, :state_change_id, ndx_found.keys],
                 [:eq, :type, "create_node"],
                 [:eq, :status, "pending"]]
      }

      sc_mh = sc_idhs.first.createMH()
      get_objs(sc_mh,sp_hash).each{|sc|ndx_found[sc[:state_change_id]] ||= true}
      ndx_found.each_pair{|sc_id,found|ret << sc_id unless found}
      ret
    end
    private :find_any_without_pending_children?

    def pending_changed_component(parent_mh,idh_list,_opts={})
      parent_field_name = DB.parent_field(parent_mh[:model_name],:state_change)
      sp_hash = {
        filter: [:and,
                 [:oneof, parent_field_name,idh_list.map{|idh|idh.get_id()}],
                 [:oneof, :type, ["install_component", "update_implementation","converge_component"]],
                 [:eq, :status, "pending"]],
        columns: [:id, :relative_order,:type,:changed_component,parent_field_name,:state_change_id].uniq
      }
      state_change_mh = parent_mh.createMH(:state_change)
      sc_with_direct_cmps = get_objs(state_change_mh,sp_hash)
      add_related_components(sc_with_direct_cmps)
    end

    def pending_changed_attribute(parent_mh,idh_list,_opts={})
      parent_field_name = DB.parent_field(parent_mh[:model_name],:state_change)
      sp_hash = {
        filter: [:and,
                 [:oneof, parent_field_name,idh_list.map{|idh|idh.get_id()}],
                 [:eq, :type, "setting"],
                 [:eq, :status, "pending"]],
        columns: [:id, :relative_order,:type,:changed_attribute,parent_field_name,:state_change_id].uniq
      }      
      state_change_mh = parent_mh.createMH(:state_change)
      sc_with_direct_cmps = get_objs(state_change_mh,sp_hash)
      add_related_components(sc_with_direct_cmps)
    end

    def add_related_components(sc_with_direct_cmps)
      component_index = {}
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
      # TODO: assumption that cmps only appear once in sc_with_direct_cmps

      sc_with_related_cmps = []
      related_cmps.map do |cmp|
        cmp[:assoc_component_ids].each do |cmp_id|
          related_sc = component_index[cmp_id].merge(component: cmp)
          sc_with_related_cmps << related_sc
        end
      end

      sc_with_direct_cmps + sc_with_related_cmps
    end

    def remove_dups_and_proc_related_components(state_changes)
      indexed_ret = {}
      # remove duplicates wrt component and process linked_ids
      state_changes.each do |sc|
        if sc[:type] == "create_node"
          indexed_ret[sc[:node][:id]] = augment_with_linked_id(sc,sc[:id])
          # TODO: ordering may do thsis anyway, but do we explicitly want to make sure if both setting adn isnatll use install as type
        elsif %w(setting install_component update_implementation converge_component).include?(sc[:type])
          indexed_ret[sc[:component][:id]] = augment_with_linked_id(indexed_ret[sc[:component][:id]] || sc.reject{|k,_v|[:attribute].include?(k)},sc[:id])
        else
          Log.error("unexpected type #{sc[:type]}; ignoring")
        end
      end
      indexed_ret.values
    end

    private

    # linked ids is link to relevant stage_change objects
    def augment_with_linked_id(state_change,id)
      if linked = state_change[:linked_ids]
        linked.include?(id) ? state_change : state_change.merge(linked_ids: linked + [id])
      else
        state_change.merge(linked_ids: [id])
      end
    end
  end
end; end

