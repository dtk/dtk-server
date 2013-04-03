module XYZ
  module TaskCreateClassMixin
    def create_from_assembly_instance(assembly,component_type,commit_msg=nil)
      target_idh = assembly.id_handle().get_parent_id_handle_with_auth_info()
      task_mh = target_idh.create_childMH(:task)

      # smoketest should not create a node
      if component_type == :smoketest
        create_nodes_task = nil
      else
        create_nodes_changes = StateChange::Assembly::node_state_changes(assembly,target_idh)
        create_nodes_task = create_nodes_task(task_mh,create_nodes_changes)
      end

      assembly_config_changes = StateChange::Assembly::component_state_changes(assembly,component_type)
      nodes = assembly_config_changes.flatten(1).map{|r|r[:node]}
      node_mh = assembly.model_handle(:node)
      node_centric_config_changes = StateChange::NodeCentric::AllMatching.component_state_changes(node_mh,:nodes => nodes)
      config_nodes_changes = combine_same_node_state_changes([node_centric_config_changes,assembly_config_changes])

      #staged_config_nodes_changes = generate_stages(config_nodes_changes)


      config_nodes_task = config_nodes_task(task_mh,config_nodes_changes,assembly.id_handle())
      ret = create_new_task(task_mh,:assembly_id => assembly[:id],:display_name => "assembly_converge", :temporal_order => "sequential",:commit_message => commit_msg)
      if create_nodes_task and config_nodes_task
        ret.add_subtask(create_nodes_task)
        ret.add_subtask(config_nodes_task)
      else
        # only one will be non null
        ret.add_subtask(create_nodes_task||config_nodes_task) 
      end
      ret
    end

    def generate_stages(state_change_list)

      nodes = Array.new

      state_change_list.each do |node_change_list|
        node_id = node_change_list.first[:node][:id]
        cmp_ids = Array.new
        node_change_list.each do |component|
          cmp_ids << component[:component][:id]
        end
        cmp_deps = Component.get_component_type_and_dependencies(cmp_ids)
        nodes << { :node_id => node_id, :component_dependency => cmp_deps }
      end

      # DEBUG SNIPPET
      require 'rubygems'
      require 'ap'
      ap "nodes"
      ap nodes


    end

    def task_when_nodes_ready_from_assembly(assembly, component_type)
      assembly_idh = assembly.id_handle()
      target_idh = assembly_idh.get_parent_id_handle_with_auth_info()
      task_mh = target_idh.create_childMH(:task)

      assembly_config_changes = StateChange::Assembly::component_state_changes(assembly,component_type)
      running_node_task = create_running_node_task(task_mh, assembly_config_changes)

      main_task = create_new_task(task_mh,:assembly_id => assembly_idh.get_id(),:display_name => "assembly_nodes_start", :temporal_order => "sequential",:commit_message => nil)
      main_task.add_subtask(running_node_task)

      return main_task
    end

    def create_from_node_group(node_group_idh,commit_msg=nil)
      ret = nil
      target_idh = node_group_idh.get_parent_id_handle_with_auth_info()
      task_mh = target_idh.create_childMH(:task)
      node_mh = target_idh.create_childMH(:node)
      node_group = node_group_idh.create_object()

      create_nodes_changes = StateChange::NodeCentric::SingleNodeGroup.node_state_changes(target_idh,:node_group => node_group)
      create_nodes_task = create_nodes_task(task_mh,create_nodes_changes)

      config_nodes_changes = StateChange::NodeCentric::SingleNodeGroup.component_state_changes(node_mh,:node_group => node_group)
      config_nodes_task = config_nodes_task(task_mh,config_nodes_changes)

      ret = create_new_task(task_mh,:temporal_order => "sequential",:node_id => node_group_idh.get_id(),:display_name => "node_group_converge", :commit_message => commit_msg)
      if create_nodes_task and config_nodes_task
        ret.add_subtask(create_nodes_task)
        ret.add_subtask(config_nodes_task)
      else
        if sub_task = create_nodes_task||config_nodes_task
          ret.add_subtask(create_nodes_task||config_nodes_task) 
        else
          ret = nil
        end
      end
      ret
    end
    #TODO: might collapse these different creates for node, node_group, assembly
    def create_from_node(node_idh,commit_msg=nil)
      ret = nil
      target_idh = node_idh.get_parent_id_handle_with_auth_info()
      task_mh = target_idh.create_childMH(:task)
      node_mh = target_idh.create_childMH(:node)
      node = node_idh.create_object().update_object!(:display_name)

      create_nodes_changes = StateChange::NodeCentric::SingleNode.node_state_changes(target_idh,:node => node)
      create_nodes_task = create_nodes_task(task_mh,create_nodes_changes)

      config_nodes_changes = StateChange::NodeCentric::SingleNode.component_state_changes(node_mh,:node => node)
      config_nodes_task = config_nodes_task(task_mh,config_nodes_changes)

      ret = create_new_task(task_mh,:temporal_order => "sequential",:node_id => node_idh.get_id(),:display_name => "node_converge", :commit_message => commit_msg)
      if create_nodes_task and config_nodes_task
        ret.add_subtask(create_nodes_task)
        ret.add_subtask(config_nodes_task)
      else
        if sub_task = create_nodes_task||config_nodes_task
          ret.add_subtask(create_nodes_task||config_nodes_task) 
        else
          ret = nil
        end
      end
      ret
    end

    def power_on_from_node(node_idh,commit_msg=nil)
      ret = nil
      target_idh = node_idh.get_parent_id_handle_with_auth_info()
      task_mh = target_idh.create_childMH(:task)
      node_mh = target_idh.create_childMH(:node)
      node = node_idh.create_object().update_object!(:display_name)

      power_on_nodes_changes = StateChange::NodeCentric::SingleNode.component_state_changes(node_mh,:node => node)
      power_on_nodes_task = create_running_node_task(task_mh,power_on_nodes_changes)

      ret = create_new_task(task_mh,:temporal_order => "sequential",:node_id => node_idh.get_id(),:display_name => "node_converge", :commit_message => commit_msg)
      if power_on_nodes_task
        ret.add_subtask(power_on_nodes_task)
      else
        ret = nil
      end
      ret
    end

    #TODO: might deprecate
    def create_from_pending_changes(parent_idh,state_change_list)
      task_mh = parent_idh.create_childMH(:task)
      grouped_state_changes = group_by_node_and_type(state_change_list)
      grouped_state_changes.each_key do |type|
        unless [Task::Action::CreateNode,Task::Action::ConfigNode].include?(type)
          Log.error("treatment of task action type #{type.to_s} not yet treated; it will be ignored")
          grouped_state_changes.delete(type)
          next
        end
      end
      #if have both create_node and config node then top level has two stages create_node then config node
      create_nodes_task = create_nodes_task(task_mh,grouped_state_changes[Task::Action::CreateNode])
      config_nodes_task = config_nodes_task(task_mh,grouped_state_changes[Task::Action::ConfigNode])
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
        executable_action = Task::Action::CreateNode.create_from_state_change(state_change_list.first.first)
        all_actions << executable_action
        ret = create_new_task(task_mh,:executable_action => executable_action) 
      else
        ret = create_new_task(task_mh,:display_name => "create_node_stage", :temporal_order => "concurrent")
        state_change_list.each do |sc|
          executable_action = Task::Action::CreateNode.create_from_state_change(sc.first)
          all_actions << executable_action
          ret.add_subtask_from_hash(:executable_action => executable_action)
          end
      end
      attr_mh = task_mh.createMH(:attribute)
      Task::Action::CreateNode.add_attributes!(attr_mh,all_actions)
      ret
    end

    def create_running_node_task(task_mh,state_change_list)
      return nil unless state_change_list and not state_change_list.empty?
      #each element will be list with single element
      ret = nil
      all_actions = Array.new
      if state_change_list.size == 1
        executable_action = Task::Action::PowerOnNode.create_from_state_change(state_change_list.first.first)
        all_actions << executable_action
        ret = create_new_task(task_mh,:executable_action => executable_action) 
      else
        ret = create_new_task(task_mh,:display_name => "create_node_stage", :temporal_order => "concurrent")
        state_change_list.each do |sc|
          executable_action = Task::Action::PowerOnNode.create_from_state_change(sc.first)
          all_actions << executable_action
          ret.add_subtask_from_hash(:executable_action => executable_action)
          end
      end
      attr_mh = task_mh.createMH(:attribute)
      Task::Action::PowerOnNode.add_attributes!(attr_mh,all_actions)
      ret
    end

    #TODO: think asseumption is that each elemnt corresponds to changes to same node; if this is case may change input datastructure 
    #so node is not repeated for each element corresponding to same node
    def config_nodes_task(task_mh,state_change_list,assembly_idh=nil)
      return nil unless state_change_list and not state_change_list.empty?
      ret = nil
      all_actions = Array.new
      if state_change_list.size == 1
        executable_action, error_msg = get_executable_action_from_state_change(state_change_list.first, assembly_idh)
        raise ErrorUsage.new(error_msg) unless executable_action
        all_actions << executable_action
        ret = create_new_task(task_mh,:executable_action => executable_action) 
      else
        ret = create_new_task(task_mh,:display_name => "config_node_stage", :temporal_order => "concurrent")
        all_errors = Array.new
        state_change_list.each do |sc|
          executable_action, error_msg = get_executable_action_from_state_change(sc,assembly_idh)
          unless executable_action
            all_errors << error_msg
            next
          end
          all_actions << executable_action
          ret.add_subtask_from_hash(:executable_action => executable_action)
        end
        raise ErrorUsage.new("\n" + all_errors.join("\n")) unless all_errors.empty?
      end
      attr_mh = task_mh.createMH(:attribute)
      Task::Action::ConfigNode.add_attributes!(attr_mh,all_actions)
      ret
    end

    # Amar
    # moved call to ConfigNode.create_from_state_change into this method for error handling with clear message to user
    # if TSort throws TSort::Cyclic error, it means intra-node cycle case
    def get_executable_action_from_state_change(state_change, assembly_idh)
      executable_action = nil
      error_msg = nil
      begin 
        executable_action = Task::Action::ConfigNode.create_from_state_change(state_change, assembly_idh)
      rescue TSort::Cyclic => e
        node = state_change.first[:node]
        display_name = node[:display_name]
        id = node[:id]
        cycle_comp_ids = e.message.match(/.*\[(.+)\]/)[1]
        component_names = Array.new
        state_change.each do |cmp|
          component_names << "#{cmp[:component][:display_name]} (ID: #{cmp[:component][:id].to_s})" if cycle_comp_ids.include?(cmp[:component][:id].to_s)
        end
        error_msg = "Intra-node components cycle detected on node '#{display_name}' (ID: #{id}) for components: #{component_names.join(', ')}"
      end
      return executable_action, error_msg
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
        "create_node" => Task::Action::CreateNode,
        "install_component" => Task::Action::ConfigNode,
        "update_implementation" => Task::Action::ConfigNode,
        "converge_component" => Task::Action::ConfigNode,
        "setting" => Task::Action::ConfigNode
      }
      @mapping_sc_to_task_action[state_change]
    end

    def create_new_task(task_mh,hash)
      create_stub(task_mh,hash)
    end
  end
end


