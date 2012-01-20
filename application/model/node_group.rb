r8_nested_require('node_group','clone')
module XYZ
  class NodeGroup < Node
    include NodeGroupClone
    def node_members()
      sp_hash = {
        :cols => [:node_member]
      }
      get_objs(sp_hash).map{|r|r[:node_member]}
    end

    def delete()
      #TODO: stub
      Model.delete_instance(id_handle())
    end
    def destroy_and_delete
      delete()
    end
    private
    #TODO: can we avoid explicitly placing this here?
     def self.db_rel()
       Node.db_rel()
     end
  end
end

