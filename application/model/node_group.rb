module XYZ
  class NodeGroup < Node
    def node_members()
      sp_hash = {
        :cols => [:node_member]
      }
      get_objs(sp_hash).map{|r|r[:node_member]}
    end

    def clone_post_copy_hook(clone_copy_output,opts={})
      super
      clone_source_obj = clone_copy_output.source_object
      
      #clone the component in all the nodes taht are a member of this node group
      #TODO: started with brute force way to do this. There is many different ways that teh computation can be optimized, such s
      #bulk cloning, flags that idniacet ops to skip when node is being cloned to mirror what is in node group
      # shortcutting implementation pointers by having it be an overriding attribute
      #copy to nodes the output object after post processing not source object
      override_attrs = {}
      node_clone_opts = [:ret_new_obj_with_cols].inject({}) do |h,k|
        opts.has_key?(k) ? h.merge(k => opts[k]) : h
      end
      node_members().each{|node|node.clone_into(clone_source_obj,override_attrs,node_clone_opts)}
    end

    def delete()
      #TODO: stub
      Model.delete_instance(id_handle())
    end
    def destroy_and_delete
      delete()
    end
    private
    #TODO: can we avoid explicitly placing this here
     def self.db_rel()
      Node.db_rel()
    end
  end
end

