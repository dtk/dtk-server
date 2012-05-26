{
  :schema=>:component,
  :table=>:ref,
  :columns=>{
    :component_template_id=>{
      :type=>:bigint,
      :foreign_key_rel_type=>:component,
      :on_delete=>:set_null,
      :on_update=>:set_null
    }
  },
  :virtual_columns=>{
    :node_with_assembly_id=> {
      :type=>:json,
      :hidden=>true,
      :remote_dependencies=>
      [{
         :model_name=>:node,
         :join_type=>:inner,
         :join_cond=>{:id=>:component_ref__node_node_id},
         :cols=>[:id,:display_name,:assembly_id]
       }]
    }
  },
  :many_to_one => [:node]
}
