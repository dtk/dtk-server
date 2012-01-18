module XYZ
  class Node_groupController < Controller
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

