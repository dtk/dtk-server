module XYZ
  class Node_groupController < Controller
    def save()
      ret = super
      if request.params["parent_model_name"] == "target"
        target_id = request.params["parent_id"]
        if ret.is_ok?
          ng_id = ret.data[:id]
          target = get_object_by_id(target_id,:target)
          target.update_ui_for_new_item(ng_id)
        end
      end
      ret
    end

    def rest__members(node_group_id)
      node_group = create_object_from_id(node_group_id)
      rest_ok_response node_group.node_members()
    end

    def rest__set_default_template_node()
      node_group_id, template_node_id = ret_non_null_request_params(:node_group_id,:template_node_id)
      node_group = create_object_from_id(node_group_id)
      node_group.update(:canonical_template_node_id => template_node_id)
      rest_ok_response
    end

    #TODO: initially implementing simple version taht takes no parameters and uses the canonical_member_id 
    def rest__clone_and_add_template_node()
      node_group_id = ret_non_null_request_params(:node_group_id)
      node_group = create_object_from_id(node_group_id)
      unless template_node = node_group.get_canonical_template_node()
        raise Error.new("Node group does not have a default templae node set")
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

