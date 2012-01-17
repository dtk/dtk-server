module XYZ
  class NodeGroup < Node
    def delete()
      #TODO: stub
      Model.delete_instance(id_handle())
    end
    private
    #TODO: can we avoid explicitly pacing this here
     def self.db_rel()
      Node.db_rel()
    end
  end
end

