{
  :schema=>:port,
  :table=>:port,
  :columns=>{
    :type=>{
      :type=>:varchar,
      :size =>50
    },
    :direction=>{
      :type=>:varchar,
      :size =>10
    },
    :connected => {:type=>:boolean},
    :external_attribute_id=>{
      :type=>:bigint,
      :foreign_key_rel_type=>:attribute,
      :on_delete=>:cascade,
      :on_update=>:cascade
    },
    :link_type=>{
      :type=>:varchar,
      :size =>50
    },
    :component_type=>{
      :type=>:varchar,
      :size =>50
    },
    :component_id=>{
      :type=>:bigint,
      :foreign_key_rel_type=>:component,
      :on_delete=>:cascade,
      :on_update=>:cascade
    },
    :link_def_id=>{
      :type=>:bigint,
      :foreign_key_rel_type=>:link_def,
      :on_delete=>:cascade,
      :on_update=>:cascade
    },
    :cardinality=>{
      :type=>:json
    },
    :location_asserted=>{
      :type=>:varchar,
      :size =>10
     },
    :containing_port_id=>{
      :type=>:bigint,
      :foreign_key_rel_type=>:port,
      :on_delete=>:set_null,
      :on_update=>:set_null
    }
  },
  :many_to_one=>[:node],
  :virtual_columns=>{
    :location=>{
      :type=>:varchar,
      :hidden=>true,
      :local_dependencies => [:location_asserted,:direction,:display_name]
    },
    :name=>{
      :type=>:varchar,
      :hidden=>true,
      :local_dependencies => [:display_name]
    },
    :node_id=>{
      :type=>ID_TYPES[:id],
      :hidden=>true,
      :local_dependencies => [:node_node_id]
    },
    :node=>{
      :type=>:json,
      :hidden=>true,
      :remote_dependencies=>
      [{
         :model_name=>:node,
         :convert => true,
         :join_type=>:inner,
         :join_cond=>{:id =>:port__node_node_id},
         :cols=>[:id,:group_id,:display_name,:assembly_id]
       }]
    },
    :link_def_info=>{
      :type=>:json,
      :hidden=>true,
      :remote_dependencies=>
      [{
         :model_name=>:link_def,
         :convert => true,
         :join_type=>:left_outer,
         :join_cond=>{:id =>:port__link_def_id},
         :cols=>[:id,:display_name,:component_component_id,:link_type,:has_external_link,:has_internal_link,:local_or_remote]
       },
       {
         :model_name=>:component,
         :convert => true,
         :join_type=>:left_outer,
         :join_cond=>{:id => :link_def__component_component_id},
         :cols=>[:id,:display_name,:component_type,:node_node_id,:implementation_id,:extended_base]
       },
       {
         :model_name=>:link_def_link,
         :convert => true,
         :join_type=>:left_outer,
         :join_cond=>{:link_def_id=>:link_def__id},
         :cols=>[:id,:display_name,:remote_component_type,:position,:content,:type]
       }]
    },
    :attribute=>{
      :type=>:json,
      :hidden=>true,
      :remote_dependencies=>
      [{
         :model_name=>:attribute,
         :alias=>:attribute_direct, 
         :join_type=>:left_outer,
         :join_cond=>{:id =>:port__external_attribute_id},
         :cols=>[:id,:display_name]
       },
       {
         :model_name=>:port,
         :alias=>:port_nested,
         :join_type=>:left_outer,
         :join_cond=>{:containing_port_id =>:port__id},
         :cols=>[:id,:display_name,:external_attribute_id]
       },
       {
         :model_name=>:attribute,
         :alias=>:attribute_nested, 
         :join_type=>:left_outer,
         :join_cond=>{:id =>:port_nested__external_attribute_id},
         :cols=>[:id,:display_name]
       }]
    }
  }
}
