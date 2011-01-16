module Ramaze::Helper
  module ProcessPendingActions
    include XYZ

    def create_task_from_pending_changes(state_change_list)
      grouped_state_changes = group_by_node_and_type(state_change_list)
      grouped_state_changes.each_key do |type|
        unless [TaskAction::CreateNode,TaskAction::ConfigNode].include?(type)
          Log.error("treatment of task action type #{type.to_s} not yet treated; it will be ignored")
          grouped_state_changes.delete(type)
          next
        end
      end
      #top level has two stages create_node then config node
#TODO: get here in refactor of this function
      temporal_order = state_changes_by_node.size == 1 ? "sequential" : "concurrent"
      top_level_task = Task.create_top_level(ret_session_context_id(),temporal_order)
      all_config_node_actions = Array.new
      all_create_node_actions = Array.new
      state_changes_by_node.each do |node_changes|
        create_node_action = TaskAction::CreateNode.create(node_changes)
        config_node_action = TaskAction::ConfigNode.create(node_changes)
        all_config_node_actions << config_node_action if config_node_action
        all_create_node_actions << create_node_action if create_node_action
        if create_node_action and config_node_action
          node_subtask = top_level_task.add_subtask({:temporal_order => "sequential"})
          node_subtask.add_subtask({:executable_action => create_node_action})
          node_subtask.add_subtask({:executable_action => config_node_action})
        else
          #one wil be non null
          top_level_task.add_subtask({:executable_action => create_node_action||config_node_action})
        end
      end
      #doing add attributes at top level rather than in each create_node_action for db access efficiency
      attr_mh = ModelHandle.new(ret_session_context_id(),:attribute)
      TaskAction::ConfigNode.add_attributes!(attr_mh,all_config_node_actions)
      TaskAction::CreateNode.add_attributes!(attr_mh,all_create_node_actions)
      top_level_task
    end

    def group_by_node_and_type(state_change_list)
      indexed_ret = Hash.new
      state_change_list.each do |sc|
        type = MappingStateChangeToTaskAction[sc[:type]]
        unless type
          Log.error("unexpected state change type encountered #{sc[:type]}; ignoring")
          next
        end
        node_id = sc[:node][:id]
        indexed_ret[type] ||= Hash.new
        indexed_ret[type][node_id] ||= Array.new
        indexed_ret[type][node_id] << sc
      end
      indexed_ret.inject({}){|ret,o|ret.merge(o[0] => o[1].values)}
    end
    MappingStateChangeToTaskAction = {
      "create_node" => TaskAction::CreateNode,
      "install-component" => TaskAction::ConfigNode,
      "setting" => TaskAction::ConfigNode
    }

    def pending_create_node(datacenter_id)
      parent_field_name = XYZ::DB.parent_field(:datacenter,:state_change)
      search_pattern_hash = {
        :relation => :state_change,
        :filter => [:and,
                    [:eq, parent_field_name, datacenter_id],
                    [:eq, :type,"create_node"],
                    [:eq, :state, "pending"]],
        :columns => [:id, :relative_order,:type,:created_node,parent_field_name,:state_change_id]
      }
      get_objects_from_search_pattern_hash(search_pattern_hash)
    end

    def pending_install_component(datacenter_id)
      parent_field_name = XYZ::DB.parent_field(:datacenter,:state_change)
      search_pattern_hash = {
        :relation => :state_change,
        :filter => [:and,
                    [:eq, parent_field_name, datacenter_id],
                    [:eq, :type,"install-component"],
                    [:eq, :state, "pending"]],
        :columns => [:id, :relative_order,:type,:installed_component,parent_field_name,:state_change_id]
      }
      actions = get_objects_from_search_pattern_hash(search_pattern_hash)
      remove_duplicate_and_add_same_component_types(actions)
    end

    def pending_changed_attribute(datacenter_id)
      parent_field_name = XYZ::DB.parent_field(:datacenter,:state_change)
      search_pattern_hash = {
        :relation => :state_change,
        :filter => [:and,
                    [:eq, parent_field_name, datacenter_id],
                    [:eq, :type,"setting"],
                    [:eq, :state, "pending"]],
        :columns => [:id, :relative_order,:type,:changed_attribute,parent_field_name,:state_change_id]
      }      
      actions = get_objects_from_search_pattern_hash(search_pattern_hash)
      remove_duplicate_and_add_same_component_types(actions)
    end

    def remove_duplicate_and_add_same_component_types(actions)
      indexed_ret = Hash.new
      #remove duplicates wrt component looking at both component and component_same_type
      actions.each do |a|
        indexed_ret[a[:component][:id]] ||= a.reject{|k,v|[:attribute,:component_same_type].include?(k)} 
        cst = a[:component_same_type]
        indexed_ret[cst[:id]] ||=  a.reject{|k,v| [:attribute,:component_same_type].include?(k)}.merge(:component => cst) if cst
      end
      indexed_ret.values
    end
  end
end

