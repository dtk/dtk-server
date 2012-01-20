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
       ng_plus_node_cmp_ids = node_cmps.map{|r|r[:id]} + [ng_cmp_id]
       attr_mh = ng_cmp.model_handle(:attribute)

       cols = AttributeLink.attribute_info_cols()
       cols << AttrFieldToMatchOn unless cols.include?(AttrFieldToMatchOn)
       cols << :component_component_id unless cols.include?(:component_component_id)
       sp_hash = {
         :cols => cols,
         :filter => [:oneof, :component_component_id, ng_plus_node_cmp_ids]
       }
       attrs = Model.get_objs(attr_mh,sp_hash)
       return if attrs.empty?

       #partition into attributes on node group and ones on nodes
       #index by AttrFieldToMatchOn
       ng_ndx = attrs.select{|r|r[:component_component_id] == ng_cmp_id}.inject({}) do |h,r|
         h.merge(r[AttrFieldToMatchOn] => r[:id])
       end
       #build up link rows to create
       attr_link_rows = attrs.select{|r|r[:component_component_id] != ng_cmp_id}.map do |r|
         index = r[AttrFieldToMatchOn]
         {
           :output_id => ng_ndx[index],
           :input_id => r[:id],
           :function => "eq"
         }
       end
       opts = {:link_fns_are_set => true, :attr_rows => attrs} 
       parent_idh =  id_handle().get_top_container_id_handle(:target,:auth_info_from_self => true)
       AttributeLink.create_attribute_links(parent_idh,attr_link_rows,opts)
     end

     AttrFieldToMatchOn = :display_name
  end
end

