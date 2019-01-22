#
# Copyright (C) 2010-2016 dtk contributors
#
# This file is part of the dtk project.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
module DTK; class Task
  module CreateClassMixin
    def create_from_assembly_instance?(assembly, opts = {})
      ret = nil
      unless task = Create.create_from_assembly_instance?(assembly, opts)
        return ret
      end
      task[:breakpoint] = opts[:breakpoint] if opts[:breakpoint]
      #alters task if needed to decompose node groups into nodes
      NodeGroupProcessing.decompose_node_groups!(task)
    end

    def create_for_ad_hoc_action(assembly, component_idh, opts = {})
      task = Create.create_for_ad_hoc_action(assembly, component_idh, opts)
      ret = NodeGroupProcessing.decompose_node_groups!(task, opts)

      # raise error if any its nodes are not running
      not_running_nodes = NodeComponent.node_components(ret.get_associated_nodes, assembly).select { |node_component| ! node_component.node_is_running? }.map(&:node)
      unless not_running_nodes.empty?
        node_is = (not_running_nodes.size == 1 ? 'node is' : 'nodes are')
        node_names = not_running_nodes.map(&:display_name).join(', ')
        fail ErrorUsage.new("Cannot execute the action because the following #{node_is} not running: #{node_names}")
      end
      ret
    end

    def create_top_level(task_mh, assembly, opts = {})
      Create.create_top_level_task(task_mh, assembly, opts)
    end

    def create_for_delete_from_database(assembly, component, node, opts = {})
      task = Create.create_for_delete_from_database(assembly, component, node, opts)
      return task if opts[:return_executable_action]
      # ret = NodeGroupProcessing.decompose_node_groups!(task, opts)

      unless opts[:skip_running_check]
        # raise error if any its nodes are not running
        not_running_nodes = task.get_associated_nodes().select { |n| n.get_and_update_operational_status!() != 'running' }
        unless not_running_nodes.empty?
          node_is = (not_running_nodes.size == 1 ? 'node is' : 'nodes are')
          node_names = not_running_nodes.map(&:display_name).join(', ')
          fail ErrorUsage.new("Cannot execute the action because the following #{node_is} not running: #{node_names}")
        end
      end

      task
    end

    def create_for_command_and_control_action(assembly, action, params, node, opts = {})
      task = Create.create_for_command_and_control_action(assembly, action, params, node, opts)
      return task if opts[:return_executable_action]
      NodeGroupProcessing.decompose_node_groups!(task, opts)
    end

    def get_delete_workflow_order(assembly, opts = {})
      target_idh = target_idh_from_assembly(assembly)
      task_mh    = target_idh.create_childMH(:task)

      if opts[:uninstall]
        return get_reversed_create_workflow_order(assembly)
      end
      task_template_content = nil
      begin
        task_template_content = Template::ConfigComponents.get_or_generate_template_content([:assembly, :node_centric], assembly, { task_action: 'delete', serialized_form: opts[:serialized_form] })
      rescue Task::Template::ParsingError => e
        return nil
      rescue Task::Template::TaskActionNotFoundError => e
        opts.merge!(uninstall: true)
        return get_reversed_create_workflow_order(assembly)
      end
      component_order_from_task_template_content(:delete, task_template_content)
    end

    private
      
    def component_order_from_task_template_content(type, task_template_content)
      if serialization_form = task_template_content && task_template_content.serialization_form
        if !serialization_form[:subtasks].nil? && serialization_form[:subtasks].length > 1
          (serialization_form[:subtasks] || []).inject([]) { |a, subtask| a + subtype_component_types(type, subtask) }
        else
          subtasks_from_serialization_form(serialization_form).inject([]) { |a, subtask| a + subtype_component_types(type, subtask) }
        end
      end
    end
  
    def subtasks_from_serialization_form(serialization_form)
      if serialization_form[:subtasks]
        serialization_form[:subtasks]
      elsif COMPONENT_OR_ACTION_KEYS[:delete].find { | key| serialization_form.has_key?(key) }
        # serialization_form has a single action or component
        [serialization_form]
      else
        []
      end
    end

    def get_reversed_create_workflow_order(assembly)
      if task_template_content = Template::ConfigComponents.get_or_generate_template_content([:assembly, :node_centric], assembly)
        if create_order = component_order_from_task_template_content(:create, task_template_content)
          create_order.reverse.uniq
        end
      end
    end

    # TODO: DTK-3010; this is hack for DTK-3010; want to call parsing logic
    COMPONENT_OR_ACTION_KEYS = {
      delete: [:ordered_components, :components, :actions, :component, :action],
      create: [:ordered_components, :components, :component, :actions]
    }
    def subtype_component_types(type, subtask)
      keys = COMPONENT_OR_ACTION_KEYS[type]
      if matching_key = keys.find { |key| subtask.has_key?(key) }
        component_or_actions = subtask[matching_key]
        component_or_actions = [component_or_actions] unless component_or_actions.kind_of?(::Array)
        component_or_actions.map do |item|
          # convert to component type form and strip off action
          item.gsub('::', '__').gsub(/\.[^\.]+$/, '')
        end
      else
        []
      end
    end
  end

  class Create
    r8_nested_require('create', 'nodes_task')

    def self.create_for_ad_hoc_action(assembly, component, opts = {})
      ad_hoc_action = Template::Action::AdHoc.new(assembly, component, opts)
      task_action_name = ad_hoc_action.task_action_name()
      task_template_content = ad_hoc_action.task_template_content

      # TODO: below needs to use action params if they exist
      task_mh = target_idh_from_assembly(assembly).create_childMH(:task)
      subtasks = task_template_content.create_subtask_instances(task_mh, assembly.id_handle())
      #create_top_level_task(task_mh, assembly, task_action: task_action_name).add_subtasks(subtasks)
      create_top_level_task(task_mh, assembly, task_action: task_action_name, retry: component[:retry], task_params: opts[:task_params]).add_subtasks(subtasks)
    end

    def self.create_for_workflow_action(assembly, task_info)
      #This should form and return the task hash in a similar way 
      #to how create_from_assembly_instance forms it
      #You mentioned trapping the code at task_template_content in create from assembly instance
      #What i dont understand is:
      #what am I looking for in task_template_content creation, I know that we get our action def there?
      #Also, what keys are necessary for our task hash to have? Should I go through the steps in 
      #create from assembly instance and try to understand how that method forms it?
      #I have processed templates in workflow adapter, and should I somehow propagate those changes here, perhaps replace
      #them over task_template_content action def value?
    end

    def self.create_for_delete_from_database(assembly, component, node, opts = {})
      unless node.is_a?(Node)
        if node.eql?('assembly_wide')
          node = assembly.has_assembly_wide_node?
        else
          leaf_nodes = assembly.get_leaf_nodes()
          node = leaf_nodes.find{|n| n[:display_name].eql?(node)}
        end
      end

      task_name = delete_from_db_task_name(assembly, component, node)
      task_mh   = target_idh_from_assembly(assembly).create_childMH(:task)
      ret       = create_top_level_task(task_mh, assembly, task_action: task_name)

      executable_action = Action::DeleteFromDatabase.create_hash(assembly, component, node, opts)
      return executable_action if opts[:return_executable_action]
      subtask = create_new_task(task_mh, executable_action: executable_action)
      ret.add_subtask(subtask)
      ret
    end

    def self.delete_from_db_task_name(assembly, component, node)
      what =
        if component
          component.get_field?(:display_name)
        elsif node
          node.get_field?(:display_name)
        else
          assembly.get_field?(:display_name)
        end
      # "delete '#{what}' from database"
      "delete from database"
    end

    def self.create_for_command_and_control_action(assembly, action, params, node, opts = {})
      task_mh = target_idh_from_assembly(assembly).create_childMH(:task)
      ret = create_top_level_task(task_mh, assembly, task_action: (opts[:task_action]||'delete_nodes'))
      executable_action = Action::CommandAndControlAction.create_hash(assembly, action, params, node, opts)
      return executable_action if opts[:return_executable_action]
      subtask = create_new_task(task_mh, executable_action: executable_action)
      ret.add_subtask(subtask)
      ret
    end

    #  opts can have keys:
    #   :component_type
    #   :commit_msg, 
    #   :task_action
    #   :start_nodes
    #   :ret_nodes_to_start
    #   TODO: ....
    def self.create_from_assembly_instance?(assembly, opts = {})      
      component_type = opts[:component_type] || :service
      target_idh     = target_idh_from_assembly(assembly)
      task_mh        = target_idh.create_childMH(:task)

      nodes_to_create, nodes_wait_for_start = nodes_to_process_in_task(assembly, Aux.hash_subset(opts, [:start_nodes, :ret_nodes_to_start]))
      case component_type
       when :service
        # start stopped nodes
        unless nodes_wait_for_start.empty?
          node_scs = StateChange::Assembly.node_state_changes(:wait_for_node, assembly, target_idh, just_leaf_nodes: true, nodes: nodes_wait_for_start)
          # TODO: misnomer Action::PowerOnNode; they really just do 'wait until started' 
          start_nodes_task = NodesTask.create_subtask(Action::PowerOnNode, task_mh, node_scs)
        end
        # TODO: DTK-2938; remove
        # create nodes
        # unless nodes_to_create.empty?
        #  node_scs = StateChange::Assembly.node_state_changes(:create_node, assembly, target_idh, just_leaf_nodes: true, nodes: nodes_to_create)
        #  create_nodes_task = NodesTask.create_subtask(Action::CreateNode, task_mh, node_scs)
        # end
        create_nodes_task = nil
       when :smoketest then nil # smoketest should not create a node
       else
        fail Error.new("Unexpected component_type (#{component_type})")
      end

      opts_tt = opts.merge(component_type_filter: component_type)
      task_template_content = Template::ConfigComponents.get_or_generate_template_content([:assembly, :node_centric], assembly, opts_tt)
      #task_template_content now contains our action def
      #In our method create for workflow action: we change those 
      stages_config_nodes_task = task_template_content.create_subtask_instances(task_mh, assembly.id_handle())

      opts.merge!({task_params: opts_tt[:task_params], content_params: task_template_content.content_params})
      ret = create_top_level_task(task_mh, assembly, Aux.hash_subset(opts, [:commit_msg, :task_action, :retry, :attempts, :task_params, :content_params]))

      if start_nodes_task.nil? && create_nodes_task.nil? && stages_config_nodes_task.empty?
        # means that no steps to execute
        return nil
      end

      ### TODO: DTK-2974: lines to end: TODO: DTK-2974 should be removed and we will use another mechanism other than check_for_breakpoint to handle breakpoints
      ids = []
      task_template_content.each do |config_node_action|
        config_node_action.each {|action| ids << action[1][0][0].id }
      end

      parent_field_name = DB.parent_field(:component, :attribute)
      sp_hash = {
          relation: :attribute,
          filter: [:oneof, parent_field_name, ids],
          columns: [:id, :display_name, parent_field_name, :external_ref, :attribute_value, :required, :dynamic, :dynamic_input, :port_type, :port_is_external, :data_type, :semantic_type, :hidden]
      }
      serialized_content = DTK::Task::Template::ConfigComponents::Persistence::AssemblyActions.get_serialized_content_from_assembly(assembly, task_action = nil, task_params: opts[:task_params])
      Log.debug("Adding subtasks: #{serialized_content}")
      ###### end: TODO: DTK-2974
      ret.add_subtask(create_nodes_task) if create_nodes_task
      ret.add_subtask(start_nodes_task) if start_nodes_task
      ret.add_subtasks(stages_config_nodes_task) unless stages_config_nodes_task.empty?
      ret[:retry] = serialized_content[:retry] unless serialized_content[:retry].nil? 
      ret[:attempts] = serialized_content[:attempts] unless serialized_content[:attempts].nil?
      ret
    end



    def self.string_between_markers(string, marker1, marker2) 
        string[/#{Regexp.escape(marker1)}(.*?)#{Regexp.escape(marker2)}/m, 1]
    end

    # returns [nodes_to_create, nodes_wait_for_start]
    #  opts can have keys:
    #   :start_nodes
    #   :ret_nodes_to_start
    def self.nodes_to_process_in_task(assembly, opts = {})
      nodes_to_create = []
      nodes_wait_for_start = []

      node_cols = [:id, :display_name, :type, :external_ref, :admin_op_status, :to_be_deleted]
      assembly_nodes = assembly.get_leaf_nodes(remove_assembly_wide_node: true, cols: node_cols)

      ng_members_to_delete = assembly_nodes.select{ |node| node[:ng_member_deleted] }
      ng_members_to_delete.each{ |node| node.destroy_and_delete(dont_change_cardinality: true) }
      assembly_nodes.reject!{ |node| ng_members_to_delete.include?(node) or  node[:to_be_deleted]}

      assembly_nodes.each do |node|
        external_ref = node.external_ref
        if !external_ref.created?
          nodes_to_create << node
        else
          if opts[:start_nodes]
            nodes_wait_for_start << node
            opts[:ret_nodes_to_start] << node
          elsif external_ref.dns_name?.nil?
            # this is handling case where task got stuck where there it is started but does not have a dns address yet
            # by putting under nodes_wait_for_start there will be a wait intil get its address
            nodes_wait_for_start << node
          end
        end
      end
      [nodes_to_create, nodes_wait_for_start]
    end
    private_class_method :nodes_to_process_in_task
      

    #TODO: below will be private when finish refactoring this file
    def self.target_idh_from_assembly(assembly)
      assembly.get_target().id_handle()
    end
    def self.create_new_task(task_mh, hash)
      Task.create_stub(task_mh, hash)
    end

    def self.create_top_level_task(task_mh, assembly, opts = {})
      task_info_hash = {
        assembly_id: assembly.id,
        display_name: opts[:task_action] || 'assembly_converge',
        temporal_order: opts[:temporal_order] || 'sequential',
        retry: opts[:retry],
        attempts: opts[:attempts],
        task_params: opts[:task_params],
        content_params: opts[:content_params]
      }
      if commit_msg = opts[:commit_msg]
        task_info_hash.merge!(commit_message: commit_msg)
      end

      Log.info("Creating new task named #{task_info_hash[:display_name]}, temporal order: #{task_info_hash[:temporal_order]}")
      create_new_task(task_mh, task_info_hash)
    end
  end

  #TODO: move from below when decide whether needed; looking to generalize above so can subsume below
  module CreateClassMixin
    def task_when_nodes_ready_from_assembly(assembly, component_type, opts)
      assembly_idh = assembly.id_handle()
      target_idh = target_idh_from_assembly(assembly)
      task_mh = target_idh.create_childMH(:task)

      main_task = create_new_task(task_mh, assembly_id: assembly_idh.get_id(), display_name: 'power_on_nodes', temporal_order: 'concurrent', commit_message: nil)
      opts.merge!(main_task: main_task)

      assembly_config_changes = StateChange::Assembly.component_state_changes(assembly, component_type)
      create_running_node_task_from_assembly(task_mh, assembly_config_changes, opts)
    end

    private

    def target_idh_from_assembly(assembly)
      Create.target_idh_from_assembly(assembly)
    end

    def create_nodes_task(task_mh, state_change_list)
      return nil unless state_change_list and not state_change_list.empty?
      # each element will be list with single element
      ret = nil
      all_actions = []
      if state_change_list.size == 1
        executable_action = Action::CreateNode.create_from_state_change(state_change_list.first.first)
        all_actions << executable_action
        ret = create_new_task(task_mh, executable_action: executable_action)
      else
        ret = create_new_task(task_mh, display_name: 'create_node_stage', temporal_order: CreateNodeStageTemporalOrder)
        state_change_list.each do |sc|
          executable_action = Action::CreateNode.create_from_state_change(sc.first)
          all_actions << executable_action
          ret.add_subtask_from_hash(executable_action: executable_action)
          end
      end
      attr_mh = task_mh.createMH(:attribute)
      Action::CreateNode.add_attributes!(attr_mh, all_actions)
      ret
    end
    CreateNodeStageTemporalOrder = 'concurrent'

    def create_running_node_task_from_assembly(task_mh, state_change_list, opts = {})
      main_task = opts[:main_task]
      nodes = opts[:nodes]
      nodes_wo_components = []

      # for powering on node with no components
      unless state_change_list and not state_change_list.empty?
        unless node = opts[:node]
          fail Error.new('Expected that :node passed in as options')
        end

        executable_action = Action::PowerOnNode.create_from_node(node)
        attr_mh = task_mh.createMH(:attribute)
        Action::PowerOnNode.add_attributes!(attr_mh, [executable_action])
        ret = create_new_task(task_mh, executable_action: executable_action, display_name: 'power_on_node')
        main_task.add_subtask(ret)

        return main_task
      end

      if nodes
        nodes_wo_components = nodes.dup
        state_change_list.each do |sc|
          if node = sc.first[:node]
            nodes_wo_components.delete_if { |n| n[:id] == node[:id] }
          end
        end
      end

      ret = nil
      all_actions = []
      if nodes_wo_components.empty?
        # if assembly start called from node/node_id context,
        # do not start all nodes but one that command is executed from
        state_change_list = state_change_list.select { |s| s.first[:node][:id] == opts[:node][:id] } if opts[:node]

        # each element will be list with single element
        if state_change_list.size == 1
          executable_action = Action::PowerOnNode.create_from_state_change(state_change_list.first.first)
          all_actions << executable_action
          ret = create_new_task(task_mh, executable_action: executable_action, display_name: 'power_on_node')
          main_task.add_subtask(ret)
        else
          # ret = create_new_task(task_mh,:display_name => "power_on_nodes", :temporal_order => "concurrent")
          state_change_list.each do |sc|
            executable_action = Action::PowerOnNode.create_from_state_change(sc.first)
            all_actions << executable_action
            main_task.add_subtask_from_hash(executable_action: executable_action, display_name: 'power_on_node')
          end
        end
      else
        nodes.each do |node|
          executable_action = Action::PowerOnNode.create_from_node(node)
          all_actions << executable_action
          ret = create_new_task(task_mh, executable_action: executable_action, display_name: 'power_on_node')
          main_task.add_subtask(ret)
        end
      end
      attr_mh = task_mh.createMH(:attribute)
      Action::PowerOnNode.add_attributes!(attr_mh, all_actions)
      main_task
    end

    def create_running_node_task(task_mh, state_change_list, opts = {})
      # for powering on node with no components
      unless state_change_list and not state_change_list.empty?
        unless node = opts[:node]
          fail Error.new('Expected that :node passed in as options')
        end
        executable_action = Action::PowerOnNode.create_from_node(node)
        attr_mh = task_mh.createMH(:attribute)
        Action::PowerOnNode.add_attributes!(attr_mh, [executable_action])
        return create_new_task(task_mh, executable_action: executable_action)
      end

      # each element will be list with single element
      ret = nil
      all_actions = []
      if state_change_list.size == 1
        executable_action = Action::PowerOnNode.create_from_state_change(state_change_list.first.first)
        all_actions << executable_action
        ret = create_new_task(task_mh, executable_action: executable_action)
      else
        # TODO: is create_new_task__create_node_stage() right?
        ret = create_new_task(task_mh, display_name: 'create_node_stage', temporal_order: 'concurrent')
        state_change_list.each do |sc|
          executable_action = Action::PowerOnNode.create_from_state_change(sc.first)
          all_actions << executable_action
          ret.add_subtask_from_hash(executable_action: executable_action)
          end
      end
      attr_mh = task_mh.createMH(:attribute)
      Action::PowerOnNode.add_attributes!(attr_mh, all_actions)
      ret
    end

    # TODO: think asseumption is that each elemnt corresponds to changes to same node; if this is case may change input datastructure
    # so node is not repeated for each element corresponding to same node
    def config_nodes_task(task_mh, state_change_list, assembly_idh = nil, stage_index = nil)
      return nil unless state_change_list and not state_change_list.empty?
      ret = nil
      all_actions = []
      if state_change_list.size == 1
        executable_action, error_msg = get_executable_action_from_state_change(state_change_list.first, assembly_idh, stage_index)
        fail ErrorUsage.new(error_msg) unless executable_action
        all_actions << executable_action
        ret = create_new_task(task_mh, display_name: "config_node_stage#{stage_index}", temporal_order: 'concurrent')
        ret.add_subtask_from_hash(executable_action: executable_action)
      else
        ret = create_new_task(task_mh, display_name: "config_node_stage#{stage_index}", temporal_order: 'concurrent')
        all_errors = []
        state_change_list.each do |sc|
          executable_action, error_msg = get_executable_action_from_state_change(sc, assembly_idh, stage_index)
          unless executable_action
            all_errors << error_msg
            next
          end
          all_actions << executable_action
          ret.add_subtask_from_hash(executable_action: executable_action)
        end
        fail ErrorUsage.new("\n" + all_errors.join("\n")) unless all_errors.empty?
      end
      attr_mh = task_mh.createMH(:attribute)
      Action::ConfigNode.add_attributes!(attr_mh, all_actions)
      ret
    end

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
        component_names = []
        state_change.each do |cmp|
          component_names << "#{cmp[:component][:display_name]} (ID: #{cmp[:component][:id]})" if cycle_comp_ids.include?(cmp[:component][:id].to_s)
        end
        error_msg = "Intra-node components cycle detected on node '#{display_name}' (ID: #{id}) for components: #{component_names.join(', ')}"
      end
      [executable_action, error_msg]
    end

    def group_by_node_and_type(state_change_list)
      indexed_ret = {}
      state_change_list.each do |sc|
        type =  map_state_change_to_task_action(sc[:type])
        unless type
          Log.error("unexpected state change type encountered #{sc[:type]}; ignoring")
          next
        end
        node_id = sc[:node][:id]
        indexed_ret[type] ||= {}
        indexed_ret[type][node_id] ||= []
        indexed_ret[type][node_id] << sc
      end
      indexed_ret.inject({}) { |ret, o| ret.merge(o[0] => o[1].values) }
    end

    def map_state_change_to_task_action(state_change)
      @mapping_sc_to_task_action ||= {
        'create_node' => Action::CreateNode,
        'install_component' => Action::ConfigNode,
        'update_implementation' => Action::ConfigNode,
        'converge_component' => Action::ConfigNode,
        'setting' => Action::ConfigNode
      }
      @mapping_sc_to_task_action[state_change]
    end

    def create_new_task(task_mh, hash)
      Create.create_new_task(task_mh, hash)
    end
  end
end; end
