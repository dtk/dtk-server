module XYZ
  class Node_groupController < Controller
    helper :node_group_helper

    def rest__list()
      rest_ok_response NodeGroup.list(model_handle())
    end

    def rest__add_component()
      node_group = create_obj(:node_group_id)
      component_template_id = ret_non_null_request_params(:component_template_id)
      new_component = node_group.add_component(id_handle(component_template_id,:component))
      rest_ok_response(:component_id => new_component.id())
    end

    def rest__info_about()
      node_group = create_obj(:node_group_id)
      about = ret_non_null_request_params(:about).to_sym
      rest_ok_response node_group.info_about(about)
    end

    #TODO: old methods that need to be re-evaluated
    def rest__members(node_group_id)
      node_group = create_object_from_id(node_group_id)
      rest_ok_response node_group.node_members()
    end

    def save()
      params = request.params
      unless params["parent_model_name"] == "target"
        super 
      else
        target_idh = target_idh_with_default(params["parent_id"])
        target_id = target_idh.get_id()
        modified_params = {"parent_id" => target_id}.merge(params)
        ret = super(modified_params)
        if ret.is_ok?
          ng_id = ret.data[:id]
          target_idh.create_object().update_ui_for_new_item(ng_id)
        end
        ret
      end
    end


    def rest__set_default_template_node()
      node_group_id, template_node_id = ret_non_null_request_params(:node_group_id,:template_node_id)
      node_group = create_object_from_id(node_group_id)
      node_group.update(:canonical_template_node_id => template_node_id.to_i)
      rest_ok_response
    end

    #TODO: initially implementing simple version taht takes no parameters and uses the canonical_member_id 
    def rest__clone_and_add_template_node()
      node_group_id = ret_non_null_request_params(:node_group_id)
      node_group = create_object_from_id(node_group_id)
      unless template_node = node_group.get_canonical_template_node()
        raise Error.new("Node group does not have a default template node set")
      end
      cloned_node_idh = node_group.clone_and_add_template_node(template_node)
      rest_ok_response(:id => cloned_node_idh.get_id)
    end

    def delete()
      id = request.params["id"]
      node_group = create_object_from_id(id)
      node_group.delete()
      if rest_request?()
        rest_ok_response(:id => id)
      else
        {:data => {:id=>id,:result=>true}}
      end
    end
  end
end

