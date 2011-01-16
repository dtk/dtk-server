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
      #if have both create_node and config node then top level has two stages create_node then config node
      create_nodes_task = create_nodes_task(grouped_state_changes[TaskAction::CreateNode])
      config_nodes_task = config_nodes_task(grouped_state_changes[TaskAction::ConfigNode])
      if create_nodes_task and config_nodes_task
        ret = create_new_task(:temporal_order => "sequential")
        ret.add_subtask(create_nodes_task)
        ret.add_subtask(config_nodes_task)
        ret
      else
        #only one wil be non null
        create_nodes_task||config_nodes_task
      end
    end

    def create_nodes_task(state_change_list)
      return nil if state_change_list.empty?
      #each element will be list with single element
      ret = nil
      all_actions = Array.new
      if state_change_list.size == 1
        executable_action = TaskAction::CreateNode.new(state_change_list.first.first)
        all_actions << executable_action
        ret = create_new_task(:executable_action => executable_action) 
      else
        ret = create_new_task(:temporal_order => "concurrent")
        state_change_list.each do |sc|
          executable_action = TaskAction::CreateNode.new(sc.first)
          all_actions << executable_action
          ret.add_subtask(:executable_action => executable_action)
          end
      end
      attr_mh = ModelHandle.new(ret_session_context_id(),:attribute)
      TaskAction::CreateNode.add_attributes!(attr_mh,all_actions)
      ret
    end

    def config_nodes_task(state_change_list)
      return nil if state_change_list.empty?
      ret = nil
      all_actions = Array.new
      if state_change_list.size == 1
        executable_action = TaskAction::ConfigNode.new(state_change_list.first)
        all_actions << executable_action
        ret = create_new_task(:executable_action => executable_action) 
      else
        ret = create_new_task(:temporal_order => "concurrent")
        state_change_list.each do |sc|
          executable_action = TaskAction::ConfigNode.new(sc)
          all_actions << executable_action
          ret.add_subtask(:executable_action => executable_action)
          end
      end
      attr_mh = ModelHandle.new(ret_session_context_id(),:attribute)
      TaskAction::ConfigNode.add_attributes!(attr_mh,all_actions)
      ret
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

    def create_new_task(hash)
      Task.new(hash,ret_session_context_id())
    end

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

