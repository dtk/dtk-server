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
      # Amar: Generating Stages for inter node dependencies
      staged_config_nodes_changes = generate_stages(config_nodes_changes)
      stages_config_nodes_task = Array.new
      staged_config_nodes_changes.each_index do |i| 
        config_nodes_task = config_nodes_task(task_mh,staged_config_nodes_changes[i],assembly.id_handle(), "_#{i+1}")
        stages_config_nodes_task << config_nodes_task if config_nodes_task
      end
      ret = create_new_task(task_mh,:assembly_id => assembly[:id],:display_name => "assembly_converge", :temporal_order => "sequential",:commit_message => commit_msg)
      ret.add_subtask(create_nodes_task) if create_nodes_task
      ret.add_subtasks(stages_config_nodes_task) unless stages_config_nodes_task.empty?
      return ret
    end

    # Generating stages in case of inter node component dependencies 
    def generate_stages(state_change_list)

      # If 'GUARDS' temporal mode set, don't generate stages workflow
      return [state_change_list] unless XYZ::Workflow.stages_mode?

      stages = Array.new
      nodes = Array.new

      # Rich: get_internode_dependencies will do things that are redundant with what is below, but shoudl eb acceptable for now
      internode_dependencies = Component.get_internode_dependencies(state_change_list)
      return [state_change_list] if internode_dependencies.empty?

      # Amar: TODO Remove this if new impl works
      # Raise error if inter node dependency cycle detected
      #error_msg_for_internode_cycle = detect_internode_cycle(internode_dependencies)
      #raise ErrorUsage.new(error_msg_for_internode_cycle) if error_msg_for_internode_cycle

      state_change_list.each do |node_change_list|
        ndx_cmp_idhs = Hash.new
        node_id = node_change_list.first[:node][:id]
        
        # Gathering all impl ids to get loaded in first config node stage
        impl_ids_list = Array.new
        node_change_list.each { |sc| impl_ids_list << sc[:component][:implementation_id] }
        
        node_change_list.each do |sc|
          cmp = sc[:component]
          ndx_cmp_idhs[cmp[:id]] ||= cmp.id_handle() 

          # Adding impl_ids_list to each node
          sc[:node][:implementation_ids_list] = impl_ids_list
        end
        cmp_deps = Component.get_component_type_and_dependencies(ndx_cmp_idhs.values)
        cmp_ids_with_deps = Task::Action::OnComponent.get_cmp_ids_with_deps(cmp_deps)

        nodes << { :node_id => node_id, :component_dependency => cmp_ids_with_deps }
      end

      stages << clean_dependencies_that_are_internode(internode_dependencies, nodes)
      # everything in each stage can be executed concurrently, only each stage must go sequentially
      prev_deps_count = internode_dependencies.size
      while stage = generate_stage(internode_dependencies)
        # Checks for inter node dependency cycle and throws error if cycle present
        prev_deps_count = detect_internode_cycle(internode_dependencies, prev_deps_count)
        stages << stage 
      end
      return populate_stages_data(stages, state_change_list)
    end

    def detect_internode_cycle(internode_dependencies, prev_deps_count)
      cur_deps_count = internode_dependencies.size
      if prev_deps_count == cur_deps_count
        # Gathering data for error's pretty print on CLI side
        cmp_dep_str = Array.new
        nds_dep_str = Array.new
        internode_dependencies.each do |dep|
          cmp_dep_str << "#{format_hash(dep[:component_dependency_names])} (#{format_hash(dep[:component_dependency])})"
          nds_dep_str << "#{format_hash(dep[:node_dependency_names])} (#{format_hash(dep[:node_dependency])})"
        end
        error_msg = "Inter-node components cycle detected.\nNodes cycle:\n#{nds_dep_str.join("\n")}\nComponents cycle:\n#{cmp_dep_str.join("\n")}"
        raise ErrorUsage.new(error_msg)
      end
      return cur_deps_count
    end
    def format_hash(h)
      h.map{|k,v| "#{k} => #{v}"}.join(',')
    end

    # Amar: TODO remove this if new impl works in more cases
    def detect_internode_cycle_old(internode_dependencies)
      error_msg = nil
      tsort_input_deps = Hash.new
      internode_dependencies.each { |cmp_dep| tsort_input_deps.merge!(cmp_dep[:component_dependency])}
      begin
        # TSort is only used for cycle detection in this case. If exception is thrown, cycle exists
        TSortHash.new(tsort_input_deps).tsort
      rescue TSort::Cyclic => e
        # Gathering data for error's pretty print on CLI side
        cycle_comp_ids = e.message.match(/.*\[(.+)\]/)[1]
        cmp_dep_str = Array.new
        nds_dep_str = Array.new
        internode_dependencies.each do |dep|
          if cycle_comp_ids.include?(dep[:component_dependency].keys.first.to_s)
            cmp_dep_str << "#{format_hash(dep[:component_dependency_names])} (#{format_hash(dep[:component_dependency])})"
            nds_dep_str << "#{format_hash(dep[:node_dependency_names])} (#{format_hash(dep[:node_dependency])})"
          end
        end
        error_msg = "Inter-node components cycle detected.\nNodes cycle:\n#{nds_dep_str.join("\n")}\nComponents cycle:\n#{cmp_dep_str.join("\n")}"
      rescue Exception => e
        # TSort is expected to fail
        # TSort is not expected to complete ordering as internode_dependencies is not full graph representation 
      end
      return error_msg
    end

    # Populating stages from original data 'state_change_list'
    def populate_stages_data(stages, state_change_list)
      stages_state_change_list = Array.new
      first_stage = true
      stages.each do |stage|
        stage_scl = Array.new
        stage.each do |cmp|
          node_id = cmp[:node_id]
          in_node_scl = state_change_list.select { |n| n.first[:node][:id] == node_id }.first
          cmp_ids = cmp[:component_dependency].keys
          out_node_scl = Array.new
          cmp_ids.each do |cmp_id|
            in_node_scl.each do |in_node_cmp|
              if in_node_cmp[:component][:id] == cmp_id
                # removing impl_ids_list from stages except from first stage. Component modules must be loaded only for first stage
                in_node_cmp[:node][:implementation_ids_list] = Array.new unless first_stage
                out_node_scl << in_node_cmp
              end
            end
          end
          stage_scl << out_node_scl
        end
        first_stage = false if first_stage
        stages_state_change_list << stage_scl
      end
      return stages_state_change_list
    end

    # This method removes intranode dependency components from nodes and returns stage_1 actions
    def clean_dependencies_that_are_internode(internode_dependencies, nodes)
      nodes.each do |node|
        internode_dependencies.each do |internode_dependency|
          parent = internode_dependency[:component_dependency].keys.first
          if node[:component_dependency].keys.include?(parent)
            node[:component_dependency].delete(parent) 
          end
        end
      end
      return nodes
    end

    # This method will remove and return stage elements from current 'internode_dependencies'
    # that are not depended on any component in current 'internode_dependencies'
    def generate_stage(internode_dependencies)
      # Return nil if all stages are generated
      return nil if internode_dependencies.empty?

      stage = Array.new
      internode_dependencies_to_rm = Array.new
      internode_dependencies.each do |internode_dependency|
        children = internode_dependency[:component_dependency].values.first
        if is_stage(internode_dependencies, children)
          internode_dependencies_to_rm << internode_dependency
          stage_element = {
            :component_dependency => internode_dependency[:component_dependency],
            :node_id => internode_dependency[:node_dependency].keys.first
          }
          stage << stage_element unless stage.include?(stage_element)
        end
      end
      internode_dependencies_to_rm.each { |rm| internode_dependencies.delete(rm) }

      return stage
    end

    def is_stage(internode_dependencies, children)
      internode_dependencies.each do |internode_dependency|
        return false if children.include?(internode_dependency[:component_dependency].keys.first)
      end
      return true
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
    def config_nodes_task(task_mh,state_change_list,assembly_idh=nil, stage_index=nil)
      return nil unless state_change_list and not state_change_list.empty?
      ret = nil
      all_actions = Array.new
      if state_change_list.size == 1
        executable_action, error_msg = get_executable_action_from_state_change(state_change_list.first, assembly_idh)
        raise ErrorUsage.new(error_msg) unless executable_action
        all_actions << executable_action
        ret = create_new_task(task_mh,:display_name => "config_node_stage#{stage_index}", :temporal_order => "concurrent")
        ret.add_subtask_from_hash(:executable_action => executable_action)
      else
        ret = create_new_task(task_mh,:display_name => "config_node_stage#{stage_index}", :temporal_order => "concurrent")
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


