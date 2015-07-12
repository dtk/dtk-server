module DTK
  class Node_groupController < AuthController
    helper :node_group_helper

    def rest__create
      display_name = ret_non_null_request_params(:display_name)
      target_id, spans_target = ret_request_params(:target_id, :spans_target)
      target_idh = target_idh_with_default(target_id)
      opts = {}
      opts[:spans_target] = true if spans_target
      new_ng_idh = NodeGroup.create_instance(target_idh, display_name, opts)
      rest_ok_response(node_group_id: new_ng_idh.get_id())
    end

    def rest__delete
      node_group = create_obj(:node_group_id)
      node_group.delete()
      rest_ok_response
    end

    def rest__list
      rest_ok_response NodeGroup.list(model_handle())
    end

    def rest__add_component
      node_group = create_obj(:node_group_id)
      component_template, component_title = ret_component_template_and_title(:component_template_id)
      new_component_idh = node_group.add_component(component_template, component_title: component_title)
      rest_ok_response(component_id: new_component_idh.get_id())
    end

    def rest__delete_component
      node_group = create_obj(:node_group_id)
      # not checking here if component_id points to valid object; check is in delete_component
      component_id = ret_non_null_request_params(:component_id)
      node_group.delete_component(id_handle(component_id, :component))
      rest_ok_response
    end

    def rest__info_about
      node_group = create_obj(:node_group_id)
      about = ret_non_null_request_params(:about).to_sym
      rest_ok_response node_group.info_about(about)
    end

    def rest__get_attributes
      node_group = create_obj(:node_group_id)
      filter = ret_request_params(:filter)
      filter &&= filter.to_sym
      rest_ok_response node_group.get_attributes_print_form(Opts.new(filter: filter))
    end

    # the body has an array each element of form
    # {:pattern => PAT, :value => VAL}
    # pat can be one of three forms
    # 1 - an id
    # 2 - a name of form ASSEM-LEVEL-ATTR or NODE/COMONENT/CMP-ATTR, or
    # 3 - a pattern (TODO: give syntax) that can pick out multiple vars
    # this returns same output as info about attributes, pruned for just new ones set
    def rest__set_attributes
      node_group = create_obj(:node_group_id)
      av_pairs = ret_params_av_pairs()
      node_group.set_attributes(av_pairs)
      rest_ok_response
    end

    def rest__get_members
      node_group = create_obj(:node_group_id)
      rest_ok_response node_group.get_node_group_members()
    end

    def rest__create_task
      node_group_idh = ret_request_param_id_handle(:node_group_id, NodeGroup)
      commit_msg = ret_request_params(:commit_msg)
      task = Task.create_from_node_group(node_group_idh, commit_msg)
      unless task
        node_group = node_group_idh.create_object().update_object!(:display_name)
        fail ErrorUsage.new("No nodes belong to node group (#{node_group[:display_name]})")
      end
      task.save!()
      rest_ok_response task_id: task.id
    end

    def rest__task_status
      node_group_idh = ret_request_param_id_handle(:node_group_id, NodeGroup)
      format = (ret_request_params(:format) || :hash).to_sym
      rest_ok_response Task::Status::NodeGroup.get_status(node_group_idh, format: format)
    end
  end
end
