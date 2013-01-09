{
  :schema=>:component,
  :table=>:ref,
  :columns=>{
    :component_type=>{:type =>:varchar,:size=>50},
    :version=>{:type=>:varchar,:size =>25},
    :has_override_version=>{:type=>:boolean,:default=>false}, #whether this has an insstance assigned to this instance, which oevrrides any global version setting of assembly this is in
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
         :cols=>[:id,:group_id,:display_name,:assembly_id]
       }]
    },
    :component_templates=> {
      :type=>:json,
      :hidden=>true,
      :remote_dependencies=>
      [{
         :model_name=>:component,
         :convert => true,
         :alias => :component_template,
         :join_type=>:inner,
         :join_cond=>{:id=>:component_ref__component_template_id},
         :cols=>[:id,:group_id,:display_name,:component_type,:only_one_per_node]
       }]
    }
  },
  :many_to_one => [:node],
  :one_to_many => [:attribute_override]
}
