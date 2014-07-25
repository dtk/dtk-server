#TODO: clean this file up; much cut and patse. moving methods we want to keep towards the top
module DTK; class Task
  module CreateClassMixin
    def create_from_assembly_instance(assembly,opts={})
      task = Create.create_from_assembly_instance(assembly,opts)
      #alters task if needed to decompose node groups into nodes
      NodeGroupProcessing.decompose_node_groups!(task)
    end
  end

  class Create
    def self.create_from_assembly_instance(assembly,opts={})
      component_type = opts[:component_type]||:service
      target_idh = target_idh_from_assembly(assembly)
      task_mh = target_idh.create_childMH(:task)
      
      ret = create_top_level_task(task_mh,assembly,Aux.hash_subset(opts,:commit_msg))

      create_nodes_task = 
        case component_type
          # smoketest should not create a node
          when :smoketest then nil
          when :service 
            create_nodes_changes = StateChange::Assembly.node_state_changes(assembly,target_idh)
            CreateNodes.create_subtask(task_mh,create_nodes_changes)
          else
            raise Error.new("Unexpected component_type (#{component_type})")
        end
      opts = {:component_type_filter => component_type}
      task_template_content = Template::ConfigComponents.get_or_generate_template_content([:assembly,:node_centric],assembly,opts)
      stages_config_nodes_task = task_template_content.create_subtask_instances(task_mh,assembly.id_handle())

      opts.merge!(:allow_empty_task => true) unless create_nodes_task.nil? && task_template_content.empty?
      ret.add_subtask(create_nodes_task) if create_nodes_task
      ret.add_subtasks(stages_config_nodes_task) unless stages_config_nodes_task.empty?
      ret
    end

    #TODO: below will be private when finish refactoring this file
    def self.target_idh_from_assembly(assembly)
      assembly.get_target().id_handle()
    end
    def self.create_new_task(task_mh,hash)
      Task.create_stub(task_mh,hash)
    end

    def self.create_top_level_task(task_mh,assembly,opts={})
      task_info_hash = {
        :assembly_id => assembly.id,
        :display_name => "assembly_converge", 
        :temporal_order => "sequential",
      }
      if commit_msg = opts[:commit_msg]
        task_info_hash.mereg!(:commit_message => commit_msg)
      end

      create_new_task(task_mh,task_info_hash)
    end

    class CreateNodes < self
      def self.create_subtask(task_mh,state_change_list_x)
        # prune out all node groups
        state_change_list = state_change_list_x.reject{|sc|sc[:node].is_node_group?()}
        return nil unless state_change_list and not state_change_list.empty?
        ret = nil
        all_actions = Array.new
        if state_change_list.size == 1
          executable_action = Action::CreateNode.create_from_state_change(state_change_list.first)
          all_actions << executable_action
          ret = create_new_task(task_mh,:executable_action => executable_action) 
        else
          ret = create_new_task(task_mh,:display_name => "create_node_stage", :temporal_order => "concurrent")
          state_change_list.each do |sc|
            executable_action = Action::CreateNode.create_from_state_change(sc)
            all_actions << executable_action
            ret.add_subtask_from_hash(:executable_action => executable_action)
          end
        end
        attr_mh = task_mh.createMH(:attribute)
        Action::CreateNode.add_attributes!(attr_mh,all_actions)
        ret
      end
    end
  end

  #TODO: move from below when decide whether needed; looking to geenralize above so can subsume below 
  module CreateClassMixin
    def create_and_start_from_assembly_instance(assembly,opts={})
      target_idh = target_idh_from_assembly(assembly)
      task_mh = target_idh.create_childMH(:task)

      component_type = opts[:component_type]||:service

      ret = Create.create_top_level_task(task_mh,assembly,Aux.hash_subset(opts,:commit_msg))

      create_node_tasks = task_when_nodes_created_and_started_from_assembly(assembly, :assembly, opts)
      ret.add_subtask(create_node_tasks) if create_node_tasks

      opts = {:component_type_filter => component_type}
      task_template_content = Template::ConfigComponents.get_or_generate_template_content([:assembly,:node_centric],assembly,opts)
      stages_config_nodes_task = task_template_content.create_subtask_instances(task_mh,assembly.id_handle())
      ret.add_subtasks(stages_config_nodes_task) unless stages_config_nodes_task.empty?
      ret
    end

    def task_when_nodes_created_and_started_from_assembly(assembly, component_type, opts={})
      assembly_idh = assembly.id_handle()
      target_idh   = target_idh_from_assembly(assembly)
      task_mh      = target_idh.create_childMH(:task)
      all_actions  = Array.new

      main_task = create_new_task(task_mh,:assembly_id => assembly_idh.get_id(),:display_name => "power_on_nodes", :temporal_order => "concurrent",:commit_message => nil)
      assembly_config_changes = StateChange::Assembly::component_state_changes(assembly,component_type)
      # running_node_task = create_running_node_task(task_mh, assembly_config_changes)

      ret = nil
      # for powering on node with no components
      unless assembly_config_changes and not assembly_config_changes.empty?
        if node = opts[:node]
          executable_action = Action::PowerOnNode.create_from_node(node)
          all_actions << executable_action
          ret = create_new_task(task_mh,:executable_action => executable_action)
          main_task.add_subtask(ret)
        elsif nodes = opts[:nodes]
          nodes.each do |node|
            executable_action = Action::PowerOnNode.create_from_node(node)
            all_actions << executable_action
            ret = create_new_task(task_mh,:executable_action => executable_action, :display_name => "power_on_node")
            main_task.add_subtask(ret)
          end
        else
          raise Error.new("Expected that :node of :nodes passed in as options")
        end

        attr_mh = task_mh.createMH(:attribute)
        Action::PowerOnNode.add_attributes!(attr_mh,all_actions)

        return main_task
      end

      if assembly_config_changes.size == 1
        executable_action = Action::PowerOnNode.create_from_state_change(assembly_config_changes.first.first)
        all_actions << executable_action
        ret = create_new_task(task_mh,:display_name => "power_on_node",:executable_action => executable_action) 
        main_task.add_subtask(ret)
      else
        # ret = create_new_task(task_mh,:display_name => "power_on_node", :temporal_order => "concurrent")
        assembly_config_changes.each do |sc|
          executable_action = Action::PowerOnNode.create_from_state_change(sc.first)
          all_actions << executable_action
          ret = create_new_task(task_mh,:display_name => "power_on_node",:executable_action => executable_action) 
          main_task.add_subtask(ret)
          # main_task.add_subtask_from_hash(:display_name => "power_on_node",:executable_action => executable_action)
          end
      end
      attr_mh = task_mh.createMH(:attribute)
      Action::PowerOnNode.add_attributes!(attr_mh,all_actions)

      main_task
    end

    def task_when_nodes_ready_from_assembly(assembly, component_type, opts)
      assembly_idh = assembly.id_handle()
      target_idh = target_idh_from_assembly(assembly)
      task_mh = target_idh.create_childMH(:task)
      
      main_task = create_new_task(task_mh,:assembly_id => assembly_idh.get_id(),:display_name => "power_on_nodes", :temporal_order => "concurrent",:commit_message => nil)
      opts.merge!(:main_task => main_task)

      assembly_config_changes = StateChange::Assembly::component_state_changes(assembly,component_type)
      running_node_task = create_running_node_task_from_assembly(task_mh, assembly_config_changes, opts)
      # running_node_task = create_running_node_task(task_mh, assembly_config_changes)

      # main_task.add_subtask(running_node_task)

      running_node_task
    end

    #This is is the 'inventory node groups', not the node groups in the service instances'
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
    # TODO: might collapse these different creates for node, node_group, assembly
    def create_from_node(node_idh,commit_msg=nil)
      ret = nil
      target_idh = node_idh.get_parent_id_handle_with_auth_info()
      task_mh = target_idh.create_childMH(:task)
      node_mh = target_idh.create_childMH(:node)
      node = node_idh.create_object().update_object!(:display_name)

      create_nodes_changes = StateChange::NodeCentric::SingleNode.node_state_changes(target_idh,:node => node)
      create_nodes_task = create_nodes_task(task_mh,create_nodes_changes)

      # TODO: need to update this to :use_task_templates
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
      power_on_nodes_task = create_running_node_task(task_mh,power_on_nodes_changes, :node => node)

      ret = create_new_task(task_mh,:temporal_order => "sequential",:node_id => node_idh.get_id(),:display_name => "node_converge", :commit_message => commit_msg)
      if power_on_nodes_task
        ret.add_subtask(power_on_nodes_task)
      else
        ret = nil
      end
      ret
    end

    # TODO: might deprecate
    def create_from_pending_changes(parent_idh,state_change_list)
      task_mh = parent_idh.create_childMH(:task)
      grouped_state_changes = group_by_node_and_type(state_change_list)
      grouped_state_changes.each_key do |type|
        unless [Action::CreateNode,Action::ConfigNode].include?(type)
          Log.error("treatment of task action type #{type.to_s} not yet treated; it will be ignored")
          grouped_state_changes.delete(type)
          next
        end
      end
      # if have both create_node and config node then top level has two stages create_node then config node
      create_nodes_task = create_nodes_task(task_mh,grouped_state_changes[Action::CreateNode])
      config_nodes_task = config_nodes_task(task_mh,grouped_state_changes[Action::ConfigNode])
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

    def create_install_agents_task(target, nodes,opts={})
      stub_create_install_agents_task(target,nodes,opts)
    end

    def stub_create_install_agents_task(target, nodes, opts={})
      target_idh = target.id_handle()
      task_mh = target_idh.create_childMH(:task)
      # executable_action = {:node=>
      #   {
      #     :id=>2147626569,
      #     :display_name=>"imported_node_1",
      #     :group_id=>2147483732,
      #     :datacenter => target,
      #     :external_ref=>{
      #       "type"=>"physical",
      #       "routable_host_address"=>"ec2-54-227-229-14.compute-1.amazonaws.com",
      #       "ssh_credentials"=>{
      #         "ssh_user"=>"ubuntu",
      #         "ssh_password"=>"1ubuntu",
      #         "ssh_rsa_private_key"=>"PRIVATE_KEY",
      #         "sudo_password"=>"PASSWD"
      #       }
      #     }
      #   }#,
      #   # :state_change_types=>["install_agent"]
      # }

      main = create_new_task(task_mh, :executable_action_type => "InstallAgent", :target_id => target_idh.get_id(), :display_name => "install_agents", :temporal_order => "concurrent")
      num_nodes = (opts[:debug_num_nodes]||3).to_i

      subtasks = []
      (1..num_nodes).each do |num|
        if node = nodes.pop
          ret = create_new_task(task_mh, :executable_action_type => "InstallAgent", :target_id => target_idh.get_id(), :display_name => "install_agent", :temporal_order => "sequential")

          executable_action = Action::PhysicalNode.create_from_physical_nodes(target, node)
          subtask = create_new_task(task_mh, :executable_action_type => "InstallAgent", :executable_action => executable_action, :display_name => "install_agent_#{num.to_s}")#, :temporal_order => "sequential")
          ret.add_subtask(subtask)

          executable_action = Action::PhysicalNode.create_smoketest_from_physical_nodes(target, node)
          subtask = create_new_task(task_mh, :executable_action_type => "ExecuteSmoketest", :executable_action => executable_action, :display_name => "execute_smoketest_#{num.to_s}")#, :temporal_order => "sequential")
          ret.add_subtask(subtask)

          main.add_subtask(ret)
        end
      end

      main
    end

   private
    def target_idh_from_assembly(assembly)
      Create.target_idh_from_assembly(assembly)
    end

    def create_nodes_task(task_mh,state_change_list)
      return nil unless state_change_list and not state_change_list.empty?
      # each element will be list with single element
      ret = nil
      all_actions = Array.new
      if state_change_list.size == 1
        executable_action = Action::CreateNode.create_from_state_change(state_change_list.first.first)
        all_actions << executable_action
        ret = create_new_task(task_mh,:executable_action => executable_action) 
      else
        ret = create_new_task(task_mh,:display_name => "create_node_stage", :temporal_order => "concurrent")
        state_change_list.each do |sc|
          executable_action = Action::CreateNode.create_from_state_change(sc.first)
          all_actions << executable_action
          ret.add_subtask_from_hash(:executable_action => executable_action)
          end
      end
      attr_mh = task_mh.createMH(:attribute)
      Action::CreateNode.add_attributes!(attr_mh,all_actions)
      ret
    end

    def create_running_node_task_from_assembly(task_mh,state_change_list,opts={})
      main_task = opts[:main_task]
      nodes = opts[:nodes]
      nodes_wo_components = []

      # for powering on node with no components
      unless state_change_list and not state_change_list.empty?
        unless node = opts[:node]
          raise Error.new("Expected that :node passed in as options")
        end

        executable_action = Action::PowerOnNode.create_from_node(node)
        attr_mh = task_mh.createMH(:attribute)
        Action::PowerOnNode.add_attributes!(attr_mh,[executable_action])
        ret = create_new_task(task_mh,:executable_action => executable_action, :display_name => "power_on_node")
        main_task.add_subtask(ret)

        return main_task
      end

      if nodes
        nodes_wo_components = nodes.dup
        state_change_list.each do |sc|
          if node = sc.first[:node]
            nodes_wo_components.delete_if{|n| n[:id] == node[:id]}
          end
        end
      end

      ret = nil
      all_actions = Array.new
      if nodes_wo_components.empty?
        # if assembly start called from node/node_id context,
        # do not start all nodes but one that command is executed from
        state_change_list = state_change_list.select{|s| s.first[:node][:id]==opts[:node][:id]} if opts[:node]

        # each element will be list with single element
        if state_change_list.size == 1
          executable_action = Action::PowerOnNode.create_from_state_change(state_change_list.first.first)
          all_actions << executable_action
          ret = create_new_task(task_mh,:executable_action => executable_action,:display_name => "power_on_node")
          main_task.add_subtask(ret)
        else
          # ret = create_new_task(task_mh,:display_name => "power_on_nodes", :temporal_order => "concurrent")
          state_change_list.each do |sc|
            executable_action = Action::PowerOnNode.create_from_state_change(sc.first)
            all_actions << executable_action
            main_task.add_subtask_from_hash(:executable_action => executable_action,:display_name => "power_on_node")
          end
        end
      else
        nodes.each do |node|
          executable_action = Action::PowerOnNode.create_from_node(node)
          all_actions << executable_action
          ret = create_new_task(task_mh,:executable_action => executable_action, :display_name => "power_on_node")
          main_task.add_subtask(ret)
        end
      end
      attr_mh = task_mh.createMH(:attribute)
      Action::PowerOnNode.add_attributes!(attr_mh,all_actions)
      main_task
    end

    def create_running_node_task(task_mh,state_change_list,opts={})
      # for powering on node with no components
      unless state_change_list and not state_change_list.empty?
        unless node = opts[:node]
          raise Error.new("Expected that :node passed in as options")
        end
        executable_action = Action::PowerOnNode.create_from_node(node)
        attr_mh = task_mh.createMH(:attribute)
        Action::PowerOnNode.add_attributes!(attr_mh,[executable_action])
        return create_new_task(task_mh,:executable_action => executable_action)
      end

      # each element will be list with single element
      ret = nil
      all_actions = Array.new
      if state_change_list.size == 1
        executable_action = Action::PowerOnNode.create_from_state_change(state_change_list.first.first)
        all_actions << executable_action
        ret = create_new_task(task_mh,:executable_action => executable_action) 
      else
        ret = create_new_task(task_mh,:display_name => "create_node_stage", :temporal_order => "concurrent")
        state_change_list.each do |sc|
          executable_action = Action::PowerOnNode.create_from_state_change(sc.first)
          all_actions << executable_action
          ret.add_subtask_from_hash(:executable_action => executable_action)
          end
      end
      attr_mh = task_mh.createMH(:attribute)
      Action::PowerOnNode.add_attributes!(attr_mh,all_actions)
      ret
    end

    # TODO: think asseumption is that each elemnt corresponds to changes to same node; if this is case may change input datastructure 
    # so node is not repeated for each element corresponding to same node
    def config_nodes_task(task_mh,state_change_list,assembly_idh=nil, stage_index=nil)
      return nil unless state_change_list and not state_change_list.empty?
      ret = nil
      all_actions = Array.new
      if state_change_list.size == 1
        executable_action, error_msg = get_executable_action_from_state_change(state_change_list.first, assembly_idh, stage_index)
        raise ErrorUsage.new(error_msg) unless executable_action
        all_actions << executable_action
        ret = create_new_task(task_mh,:display_name => "config_node_stage#{stage_index}", :temporal_order => "concurrent")
        ret.add_subtask_from_hash(:executable_action => executable_action)
      else
        ret = create_new_task(task_mh,:display_name => "config_node_stage#{stage_index}", :temporal_order => "concurrent")
        all_errors = Array.new
        state_change_list.each do |sc|
          executable_action, error_msg = get_executable_action_from_state_change(sc, assembly_idh, stage_index)
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
      Action::ConfigNode.add_attributes!(attr_mh,all_actions)
      ret
    end

    # Amar
    # moved call to ConfigNode.create_from_state_change into this method for error handling with clear message to user
    # if TSort throws TSort::Cyclic error, it means intra-node cycle case
    def get_executable_action_from_state_change(state_change, assembly_idh, stage_index)
      executable_action = nil
      error_msg = nil
      begin 
        executable_action = Action::ConfigNode.create_from_state_change(state_change, assembly_idh)
        executable_action.set_inter_node_stage!(stage_index)
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
        "create_node" => Action::CreateNode,
        "install_component" => Action::ConfigNode,
        "update_implementation" => Action::ConfigNode,
        "converge_component" => Action::ConfigNode,
        "setting" => Action::ConfigNode
      }
      @mapping_sc_to_task_action[state_change]
    end

    def create_new_task(task_mh,hash)
      Create.create_new_task(task_mh,hash)
    end
  end
end; end



