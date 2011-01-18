module Ramaze::Helper
  module GetPendingChanges
    include XYZ
    def pending_changes_in_datacenter(datacenter_id)
      last_level = pending_changes_one_level(:datacenter,[datacenter_id])
      ret = Array.new
      while not last_level.empty?
        ret += last_level
        last_level = pending_changes_one_level(:state_change,last_level.map{|x|x[:id]})
      end
      remove_duplicate_and_add_same_component_types(ret)
    end
    
    def pending_changes_one_level(parent_model_name,id_list)
      actions = 
        pending_create_node(parent_model_name,id_list) + 
        pending_install_component(parent_model_name,id_list) +
        pending_changed_attribute(parent_model_name,id_list)
    end

    def pending_create_node(parent_model_name,id_list)
      parent_field_name = XYZ::DB.parent_field(parent_model_name,:state_change)
      search_pattern_hash = {
        :relation => :state_change,
        :filter => [:and,
                    [:oneof, parent_field_name,id_list],
                    [:eq, :type,"create_node"],
                    [:eq, :state, "pending"]],
        :columns => [:id, :relative_order,:type,:created_node,parent_field_name,:state_change_id].uniq
      }
      get_objects_from_search_pattern_hash(search_pattern_hash)
    end

    def pending_install_component(parent_model_name,id_list)
      parent_field_name = XYZ::DB.parent_field(parent_model_name,:state_change)
      search_pattern_hash = {
        :relation => :state_change,
        :filter => [:and,
                    [:oneof, parent_field_name, id_list],
                    [:eq, :type,"install-component"],
                    [:eq, :state, "pending"]],
        :columns => [:id, :relative_order,:type,:installed_component,parent_field_name,:state_change_id].uniq
      }
      get_objects_from_search_pattern_hash(search_pattern_hash)
    end

    def pending_changed_attribute(parent_model_name,id_list)
      parent_field_name = XYZ::DB.parent_field(parent_model_name,:state_change)
      search_pattern_hash = {
        :relation => :state_change,
        :filter => [:and,
                    [:oneof, parent_field_name, id_list],
                    [:eq, :type,"setting"],
                    [:eq, :state, "pending"]],
        :columns => [:id, :relative_order,:type,:changed_attribute,parent_field_name,:state_change_id].uniq
      }      
      get_objects_from_search_pattern_hash(search_pattern_hash)
    end

    def remove_duplicate_and_add_same_component_types(state_changes)
      indexed_ret = Hash.new
      #remove duplicates wrt component looking at both component and component_same_type
      state_changes.each do |sc|
        if sc[:type] == "create_node"
          indexed_ret[sc[:node][:id]] = sc
        elsif ["setting","install-component"].include?(sc[:type])
          indexed_ret[sc[:component][:id]] ||= sc.reject{|k,v|[:attribute,:component_same_type].include?(k)} 
          cst = sc[:component_same_type]
          indexed_ret[cst[:id]] ||=  sc.reject{|k,v| [:attribute,:component_same_type].include?(k)}.merge(:component => cst) if cst
        else
          Log.error("unexepceted type #{sc[:type]}; ignoring")
        end
      end
      indexed_ret.values
    end
  end
end

