module XYZ
  class Node_groupController < Controller
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

