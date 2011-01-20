module Ramaze::Helper
  module CreateTasksFromPendingChanges
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
      return nil unless state_change_list and not state_change_list.empty?
      #each element will be list with single element
      ret = nil
      all_actions = Array.new
      if state_change_list.size == 1
        executable_action = TaskAction::CreateNode.new(state_change_list.first.first)
        all_actions << executable_action
        ret = create_new_task(:executable_action => executable_action) 
      else
        ret = create_new_task(:display_name => "create_node_stage", :temporal_order => "concurrent")
        state_change_list.each do |sc|
          executable_action = TaskAction::CreateNode.new(sc.first)
          all_actions << executable_action
          ret.add_subtask_from_hash(:executable_action => executable_action)
          end
      end
      attr_mh = ModelHandle.new(ret_session_context_id(),:attribute)
      TaskAction::CreateNode.add_attributes!(attr_mh,all_actions)
      ret
    end

    def config_nodes_task(state_change_list)
      return nil unless state_change_list and not state_change_list.empty?
      ret = nil
      all_actions = Array.new
      if state_change_list.size == 1
        executable_action = TaskAction::ConfigNode.new(state_change_list.first)
        all_actions << executable_action
        ret = create_new_task(:executable_action => executable_action) 
      else
        ret = create_new_task(:display_name => "config_node_stage", :temporal_order => "concurrent")
        state_change_list.each do |sc|
          executable_action = TaskAction::ConfigNode.new(sc)
          all_actions << executable_action
          ret.add_subtask_from_hash(:executable_action => executable_action)
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
      "install_component" => TaskAction::ConfigNode,
      "setting" => TaskAction::ConfigNode
    }

    def create_new_task(hash)
      Task.new(hash,ret_session_context_id())
    end
    #####
    #For adding i18n strings
    #TODO: may move to another helper file
    include R8Tpl::Utility::I18n
    def add_i18n_strings_to_rendered_tasks!(task,i18n=nil)
      model_name = task[:level] && task[:level].to_sym
      if model_name and KeysToMap.keys.include?(model_name)
        i18n ||= KeysToMap.keys.inject({}){|h,m|h.merge(m => get_model_i18n(m))}
        source = task[KeysToMap[model_name][0]]
        target_key = KeysToMap[model_name][1]
        task[target_key] ||= i18n[model_name][source.to_sym] if source
      end
      (task[:children]||[]).map{|t|add_i18n_strings_to_rendered_tasks!(t)}
    end
    KeysToMap = {
      :component => [:component_name,:component_i18n],
      :attribute => [:attribute_name,:attribute_i18n],
    }
  end
end

