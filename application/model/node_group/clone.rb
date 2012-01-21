module XYZ
  module NodeGroupClone
    def clone_post_copy_hook(clone_copy_output,opts={})
      #TODO: for simplicity not creating pending changes for node groups; 
      #future enhancement may be to create these, for example, for accounting reasons

      super_opts = opts.merge(:donot_create_pending_changes => true)
      super(clone_copy_output,super_opts)
      opts[:outermost_ports] = super_opts[:outermost_ports] if super_opts[:outermost_ports]

      clone_source_obj = clone_copy_output.source_object
      override_attrs = {}
      node_clone_opts = [:ret_new_obj_with_cols].inject({}) do |h,k|
        opts.has_key?(k) ? h.merge(k => opts[k]) : h
      end
      node_members().each{|node|node.clone_into(clone_source_obj,override_attrs,node_clone_opts)}
=begin
DEPRECATED
      node_components = node_members().map{|node|node.clone_into(clone_source_obj,override_attrs,node_clone_opts)}

      unless node_components.empty?
        ng_component = clone_copy_output.objects.first
        add_links_between_ng_and_node_components(ng_component,node_components)
      end
=end
    end
   private
=begin
TODO: deprecated
this is use technicaue that links between ng and component attributes and indirect propagation; problematic when the node groupo side has output attribute
alternative is adding links at time that node to ng link is added and special processing when attribute changed at ng level
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
       opts = {:link_fns_are_set => true, :donot_create_pending_changes => true, :attr_rows => attrs} 
       parent_idh =  id_handle().get_top_container_id_handle(:target,:auth_info_from_self => true)
       AttributeLink.create_attribute_links(parent_idh,attr_link_rows,opts)
     end

     AttrFieldToMatchOn = :display_name
=end
  end
end
