#TODO: move to methods on state changes
module Ramaze::Helper
  module GetPendingChanges
    include XYZ
    def flat_list_pending_changes_in_datacenter(datacenter_id)
      last_level = pending_changes_one_level_raw(:datacenter,[datacenter_id])
      ret = Array.new
      while not last_level.empty?
        ret += last_level
        last_level = pending_changes_one_level_raw(:state_change,last_level.map{|x|x[:id]})
      end
      remove_dups_and_proc_related_components(ret)
    end


    def pending_changes_one_level_raw(parent_model_name,id_list)
      pending_create_node(parent_model_name,id_list) + 
        pending_changed_component(parent_model_name,id_list) +
        pending_changed_attribute(parent_model_name,id_list)
    end

    def pending_create_node(parent_model_name,id_list)
      parent_field_name = XYZ::DB.parent_field(parent_model_name,:state_change)
      sp_hash = {
        :relation => :state_change,
        :filter => [:and,
                    [:oneof, parent_field_name,id_list],
                    [:eq, :type, "create_node"],
                    [:eq, :status, "pending"]],
        :columns => [:id,:relative_order,:type,:created_node,parent_field_name,:state_change_id].uniq
      }
      state_change_mh = model_handle(:state_change)
      Model.get_objects_from_sp_hash(state_change_mh,sp_hash)
    end

    def pending_changed_component(parent_model_name,id_list)
      parent_field_name = XYZ::DB.parent_field(parent_model_name,:state_change)
      sp_hash = {
        :relation => :state_change,
        :filter => [:and,
                    [:oneof, parent_field_name, id_list],
                    [:oneof, :type, ["install_component", "update_implementation","rerun_component"]],
                    [:eq, :status, "pending"]],
        :columns => [:id, :relative_order,:type,:changed_component,parent_field_name,:state_change_id].uniq
      }
      state_change_mh = model_handle(:state_change)
      sc_with_direct_cmps = Model.get_objects_from_sp_hash(state_change_mh,sp_hash)
      add_related_components(sc_with_direct_cmps)
    end

    def pending_changed_attribute(parent_model_name,id_list)
      parent_field_name = XYZ::DB.parent_field(parent_model_name,:state_change)
      sp_hash = {
        :relation => :state_change,
        :filter => [:and,
                    [:oneof, parent_field_name, id_list],
                    [:eq, :type, "setting"],
                    [:eq, :status, "pending"]],
        :columns => [:id, :relative_order,:type,:changed_attribute,parent_field_name,:state_change_id].uniq
      }      
      state_change_mh = model_handle(:state_change)
      sc_with_direct_cmps = Model.get_objects_from_sp_hash(state_change_mh,sp_hash)
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
          #TODO: ordering may do thsi anyway, but do we explicitly want to make sure if both setting adn isnatll use install as type
        elsif ["setting","install_component","update_implementation","rerun_component"].include?(sc[:type])
          indexed_ret[sc[:component][:id]] = augment_with_linked_id(indexed_ret[sc[:component][:id]] || sc.reject{|k,v|[:attribute].include?(k)},sc[:id])
        else
          Log.error("unexpected type #{sc[:type]}; ignoring")
        end
      end
      indexed_ret.values
    end

   private
    def augment_with_linked_id(state_change,id)
      if linked = state_change[:linked_ids]
        linked.include?(id) ? state_change : state_change.merge(:linked_ids => linked + [id])
      else
        state_change.merge(:linked_ids => [id])
      end
    end
  end
end

