module XYZ
  class Node_groupController < Controller
    def save()
      ret = super
      if request.params["parent_model_name"] == "target"
        target_id = request.params["parent_id"]
        if ret.is_ok?
          ng_id = ret.data[:id]
          target = get_object_by_id(target_id,:target)
          target_ui = target[:ui]||{:items=>{}}
          target_ui[:items][ng_id.to_s.to_sym] = {}
          update_from_hash(target_id,{:ui=>target_ui})
        end
      end
      ret
    end

    def rest__members(node_group_id)
      node_group = create_object_from_id(node_group_id)
      rest_ok_response node_group.node_members()
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

