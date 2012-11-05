module XYZ
  module TaskCreateClassMixin
    def create_from_pending_changes(parent_idh,state_change_list)
      task_mh = parent_idh.create_childMH(:task)
      grouped_state_changes = group_by_node_and_type(state_change_list)
      grouped_state_changes.each_key do |type|
        unless [TaskAction::CreateNode,TaskAction::ConfigNode].include?(type)
          Log.error("treatment of task action type #{type.to_s} not yet treated; it will be ignored")
          grouped_state_changes.delete(type)
          next
        end
      end
      #if have both create_node and config node then top level has two stages create_node then config node
      create_nodes_task = create_nodes_task(task_mh,grouped_state_changes[TaskAction::CreateNode])
      config_nodes_task = config_nodes_task(task_mh,grouped_state_changes[TaskAction::ConfigNode])
      if create_nodes_task and config_nodes_task
        ret = create_new_task(task_mh,:temporal_order => "sequential")
        ret.add_subtask(create_nodes_task)
        ret.add_subtask(config_nodes_task)
        ret
      else
        ret = create_new_task(task_mh,:temporal_order => "sequential")
        ret.add_subtask(create_nodes_task||config_nodes_task) #only one wil be non null
        ret
      end
    end

    def create_from_assembly_instance(assembly_idh,component_type,commit_msg=nil)
      target_idh = assembly_idh.get_parent_id_handle_with_auth_info()
      task_mh = target_idh.create_childMH(:task)

      #smoketest should not create a node
      if component_type == :smoketest
        create_nodes_task = nil
      else
        create_nodes_changes = StateChange::Assembly::node_state_changes(assembly_idh,target_idh)
        create_nodes_task = create_nodes_task(task_mh,create_nodes_changes)
      end

      assembly_config_changes = StateChange::Assembly::component_state_changes(assembly_idh,component_type)
      nodes = assembly_config_changes.flatten(1).map{|r|r[:node]}
      node_mh = assembly_idh.createMH(:node)
      node_centric_config_changes = StateChange::NodeCentric.component_state_changes(node_mh,nodes)
      config_nodes_changes = combine_same_node_state_changes([node_centric_config_changes,assembly_config_changes])
      config_nodes_task = config_nodes_task(task_mh,config_nodes_changes,assembly_idh)

      ret = create_new_task(task_mh,:assembly_id => assembly_idh.get_id(),:temporal_order => "sequential",:commit_message => commit_msg)
      if create_nodes_task and config_nodes_task
        ret.add_subtask(create_nodes_task)
        ret.add_subtask(config_nodes_task)
      else
        ret.add_subtask(create_nodes_task||config_nodes_task) #only one will be non null
      end
      ret
    end

   private
    def combine_same_node_state_changes(sc_list_array)
      #shortcut if one eleemnt is non-null
      non_null = sc_list_array.reject{|sc_list|sc_list.empty?}
      unless non_null.size > 1
        return non_null.first||[]
      end
      ndx_ret = Hash.new
      non_null.each do |sc_list|
        sc_list.each{|list|list.each{|sc|(ndx_ret[sc[:node][:id]] ||= Array.new) << sc}}
      end
      ndx_ret.values
    end

    def create_nodes_task(task_mh,state_change_list)
      return nil unless state_change_list and not state_change_list.empty?
      #each element will be list with single element
      ret = nil
      all_actions = Array.new
      if state_change_list.size == 1
        executable_action = TaskAction::CreateNode.create_from_state_change(state_change_list.first.first)
        all_actions << executable_action
        ret = create_new_task(task_mh,:executable_action => executable_action) 
      else
        ret = create_new_task(task_mh,:display_name => "create_node_stage", :temporal_order => "concurrent")
        state_change_list.each do |sc|
          executable_action = TaskAction::CreateNode.create_from_state_change(sc.first)
          all_actions << executable_action
          ret.add_subtask_from_hash(:executable_action => executable_action)
          end
      end
      attr_mh = task_mh.createMH(:attribute)
      TaskAction::CreateNode.add_attributes!(attr_mh,all_actions)
      ret
    end

    #TODO: think asseumption is that each elemnt corresponds to changes to same node; if this is case may change input datastructure 
    #so node is not repeated for each element corresponding to same node
    def config_nodes_task(task_mh,state_change_list,assembly_idh=nil)
      return nil unless state_change_list and not state_change_list.empty?
      ret = nil
      all_actions = Array.new
      if state_change_list.size == 1
        executable_action = TaskAction::ConfigNode.create_from_state_change(state_change_list.first,assembly_idh)
        all_actions << executable_action
        ret = create_new_task(task_mh,:executable_action => executable_action) 
      else
        ret = create_new_task(task_mh,:display_name => "config_node_stage", :temporal_order => "concurrent")
        state_change_list.each do |sc|
          executable_action = TaskAction::ConfigNode.create_from_state_change(sc,assembly_idh)
          all_actions << executable_action
          ret.add_subtask_from_hash(:executable_action => executable_action)
          end
      end
      attr_mh = task_mh.createMH(:attribute)
      TaskAction::ConfigNode.add_attributes!(attr_mh,all_actions)
      ret
    end

    def group_by_node_and_type(state_change_list)
      indexed_ret = Hash.new
      state_change_list.each do |sc|
        type =  map_state_change_to_task_action(sc[:type])
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
    
    def map_state_change_to_task_action(state_change)
      @mapping_sc_to_task_action ||= {
        "create_node" => TaskAction::CreateNode,
        "install_component" => TaskAction::ConfigNode,
        "update_implementation" => TaskAction::ConfigNode,
        "converge_component" => TaskAction::ConfigNode,
        "setting" => TaskAction::ConfigNode
      }
      @mapping_sc_to_task_action[state_change]
    end

    def create_new_task(task_mh,hash)
      create_stub(task_mh,hash)
    end
  end
end


