module XYZ
  class NodeGroup < Node
    def node_members()
      sp_hash = {
        :cols => [:node_member]
      }
      get_objs(sp_hash).map{|r|r[:node_member]}
    end

    def clone_post_copy_hook(clone_copy_output,opts={})
      #TODO: for simplicity not creating pending changes for node groups; 
      #future enhancement may be to create these, for example, for accounting reasons
      super(clone_copy_output,opts.merge(:donot_create_pending_changes => true))
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
      node_components = node_members().map{|node|node.clone_into(clone_source_obj,override_attrs,node_clone_opts)}
      unless node_components.empty?
        ng_component = clone_copy_output.objects.first
        add_links_between_ng_and_node_components(ng_component,node_components)
      end
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

     def add_links_between_ng_and_node_components(ng_cmp,node_cmps)
       #get all the relevant attributes
       ng_cmp_id = ng_cmp[:id]
       sp_hash = {
         :cols => [:id,AttributeFieldToMatchOn,:component_component_id],
         :filter => [:oneof, :component_component_id,node_cmps.map{|r|r[:id]} + [ng_cmp_id]]
       }
       attr_mh = ng_cmp.model_handle(:attribute)
       attrs = Model.get_objs(attr_mh,sp_hash)
       return if attrs.empty?
       #partition into attributes on node group and ones on nodes
       #index by AttributeFieldToMatchOn
       ng_ndx = attrs.select{|r|r[:component_component_id] == ng_cmp_id}.inject({}) do |h,r|
         h.merge(r[AttributeFieldToMatchOn] => r[:id])
       end
       #build up link rows to create
       attr_link_rows = attrs.select{|r|r[:component_component_id] != ng_cmp_id}.map do |r|
         index = r[AttributeFieldToMatchOn]
         {
           :output_id => ng_ndx[index],
           :input_id => r[:id]
         }
       end
       pp attr_link_rows
       #AttributeLink.create_attribute_links(parent_idh,attr_link_rows)
     end

     AttributeFieldToMatchOn = :display_name
  end
end

