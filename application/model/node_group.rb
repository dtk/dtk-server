module XYZ
  class NodeGroup < Node
    def delete()
      #TODO: stub
      Model.delete_instance(id_handle())
    end
  end
end

