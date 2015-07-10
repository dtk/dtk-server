module XYZ
  class NodeController < AuthController
    helper :node_helper
    helper :rest_async

    ### mcollective actions
    def rest__initiate_get_netstats
      node = create_node_obj(:node_id)
      queue = ActionResultsQueue.new
      # TODO: Move GetNetstas MColl action class to shared location between assembly and node controllers
      Assembly::Instance::Action::GetNetstats.initiate([node], queue)
      rest_ok_response action_results_id: queue.id
    end

    def rest__initiate_get_ps
      node = create_node_obj(:node_id)
      queue = ActionResultsQueue.new

      Assembly::Instance::Action::GetPs.initiate([node], queue, :node)
      rest_ok_response action_results_id: queue.id
    end

    def rest__initiate_execute_tests
      node = create_node_obj(:node_id)
      queue = ActionResultsQueue.new

      Assembly::Instance::Action::ExecuteTestsV2.initiate([node], queue, :node)
      rest_ok_response action_results_id: queue.id
    end

    def rest__get_action_results
      # TODO: to be safe need to garbage collect on ActionResultsQueue in case miss anything
      action_results_id = ret_non_null_request_params(:action_results_id)
      ret_only_if_complete = ret_request_param_boolean(:return_only_if_complete)
      disable_post_processing = ret_request_param_boolean(:disable_post_processing)
      response = nil
      if ret_request_param_boolean(:using_simple_queue)
        respone  = rest_ok_response SimpleActionQueue.get_results(action_results_id)
      else
        response = rest_ok_response ActionResultsQueue.get_results(action_results_id, ret_only_if_complete, disable_post_processing)
      end

      response
    end

    #### create and delete actions ###
    def rest__add_component
      node = create_node_obj(:node_id)
      component_template, component_title = ret_component_template_and_title(:component_template_name)
      new_component_idh = node.add_component(component_template, component_title: component_title)
      rest_ok_response(component_id: new_component_idh.get_id())
    end

    def rest__delete_component
      node = create_node_obj(:node_id)
      # not checking here if component_id points to valid object; check is in delete_component
      component_id = ret_non_null_request_params(:component_id)
      node.delete_component(id_handle(component_id, :component))
      rest_ok_response
    end

    def rest__destroy_and_delete
      node = create_node_obj(:node_id)
      node.destroy_and_delete()
      rest_ok_response
    end

    def rest__start
      node     = create_node_obj(:node_id)
      nodes    = get_objects(:node, id: node[:id])
      node_idh = ret_request_param_id_handle(:node_id)

      nodes, is_valid, error_msg = node_valid_for_aws?(nodes, :stopped)

      unless is_valid
        return rest_ok_response(errors: [error_msg])
      end

      queue = SimpleActionQueue.new

      user_object  = ::DTK::CurrentSession.new.user_object()
      CreateThread.defer_with_session(user_object, Ramaze::Current.session) do
        # invoking command to start the nodes
        CommandAndControl.start_instances(nodes)

        task = Task.power_on_from_node(node_idh)
        task.save!()

        queue.set_result(task_id: task.id)
      end

      rest_ok_response action_results_id: queue.id
    end

    def rest__stop
      node  = create_node_obj(:node_id)
      nodes = get_objects(:node, id: node[:id])

      nodes, is_valid, error_msg = node_valid_for_aws?(nodes, :running)

      unless is_valid
       return rest_ok_response(errors: [error_msg])
      end

      Node.stop_instances(nodes)
      rest_ok_response status: :ok
    end

    def node_valid_for_aws?(nodes, status_pattern)
      # check if staged
      if nodes.first[:type] == Node::Type::Node.staged
        return nodes, false, "Node with id '#{nodes.first[:id]}' is 'staged' and as such cannot be started/stopped."
      end

      # check for status -> this will translate to /running|pending/ and /stopped|pending/ checks
      node = nodes.first[:admin_op_status] =~ Regexp.new("#{status_pattern}|pending")
      if node.nil?
        return nodes, false, "There are no #{status_pattern} nodes with id '#{nodes.first[:id]}'"
      end

      [nodes, true, nil]
    end

    #### end: create and delete actions ###

    #### list and info actions ###
    def rest__list
      target_name, is_list_all = ret_request_params(:target_indentifier, :is_list_all)

      target_id = DTK::Datacenter.name_to_id(model_handle(:datacenter), target_name) if target_name && !target_name.empty?
      response = ret_nodes_by_subtype_class(model_handle(), target_id: target_id, is_list_all: is_list_all)
      rest_ok_response response
    end

    def rest__info
      node, subtype = ret_node_params_object_and_subtype()
       unless subtype == :instance
         fail ErrorUsage::BadParamValue.new(:subtype, subtype)
       end
      rest_ok_response node.info(print_form: true), encode_into: :yaml
    end

    def rest__info_about
      node, subtype = ret_node_params_object_and_subtype()
      about = ret_non_null_request_params(:about).to_sym
       unless AboutEnum[subtype].include?(about)
         fail ErrorUsage::BadParamValue.new(:about, AboutEnum[subtype])
       end
      rest_ok_response node.info_about(about)
    end
    AboutEnum = {
      instance: [:components, :attributes],
      #      :template => [:nodes,:components,:targets]
    }

    def rest__get_attributes
      node = create_node_obj(:node_id)
      filter = ret_request_params(:filter)
      opts = (filter ? { filter: filter.to_sym } : {})
      rest_ok_response node.get_attributes_print_form(opts)
    end

    # the body has an array each element of form
    # {:pattern => PAT, :value => VAL}
    # pat can be one of three forms
    # 1 - an id
    # 2 - a name of form ASSEM-LEVEL-ATTR or NODE/COMONENT/CMP-ATTR, or
    # 3 - a pattern (TODO: give syntax) that can pick out multiple vars
    # this returns same output as info about attributes, pruned for just new ones set
    def rest__set_attributes
      node = create_node_obj(:node_id)
      av_pairs = ret_params_av_pairs()
      node.set_attributes(av_pairs)
      rest_ok_response
    end

    #### end: list and info actions ###

    #### creates tasks to execute/converge assemblies and monitor status
    def rest__stage
      target = create_target_instance_with_default(:target_id)
      unless node_binding_rs = node_binding_ruleset?(:node_template_identifier)
        fail ErrorUsage.new('Missing node template identifier')
      end
      opts = {}
      if node_name = ret_request_params(:name)
        opts[:override_attrs] = { display_name: node_name }
      end
      node_instance_idh = node_binding_rs.clone_or_match(target, opts)
      rest_ok_response node_id: node_instance_idh.get_id()
    end

    def rest__find_violations
      node = create_node_obj(:node_id)
      violation_objects = node.find_violations()
      violation_table = violation_objects.map do |v|
        { type: v.type(), description: v.description() }
      end.sort { |a, b| a[:type].to_s <=> b[:type].to_s }
      rest_ok_response violation_table
    end

    def rest__create_task
      node_idh = ret_request_param_id_handle(:node_id)
      commit_msg = ret_request_params(:commit_msg)
      unless task = Task.create_from_node(node_idh, commit_msg)
        fail ErrorUsage.new('No changes to converge')
      end
      task.save!()
      rest_ok_response task_id: task.id
    end

    def rest__task_status
      node_idh = ret_request_param_id_handle(:node_id)
      format = (ret_request_params(:format) || :hash).to_sym
      rest_ok_response Task::Status::Node.get_status(node_idh, format: format)
    end
    #### end: creates tasks to execute/converge assemblies and monitor status

    def rest__image_upgrade
      old_image_id, new_image_id = ret_non_null_request_params(:old_image_id, :new_image_id)
      Node::Template.image_upgrade(model_handle(), old_image_id, new_image_id)
      rest_ok_response
    end

    def rest__add_node_template
      target = create_target_instance_with_default(:target_id)
      node_template_name, image_id = ret_non_null_request_params(:node_template_name, :image_id)
      opts = ret_params_hash(:operating_system, :size_array)
      Node::Template.create_or_update_node_template(target, node_template_name, image_id, opts)
      rest_ok_response
    end

    def rest__delete_node_template
      node_binding_ruleset = create_obj(:node_template_name, NodeBindingRuleset)
      Node::Template.delete_node_template(node_binding_ruleset)
      rest_ok_response
    end

    def rest__get_op_status
      node = create_node_obj(:node_id)
      rest_deferred_response do |handle|
        status = node.get_and_update_status!()
        handle.rest_ok_response(op_status: status)
      end
    end
  end
end
