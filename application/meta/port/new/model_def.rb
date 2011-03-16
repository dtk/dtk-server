{
  :schema=>:port,
  :table=>:port,
  :columns=>{
    :type=>{
      :type=>:varchar,
      :size =>25
    },
    :direction=>{
      :type=>:varchar,
      :size =>10
    },
    :external_attribute_id=>{
      :type=>:bigint,
      :foreign_key_rel_type=>:attribute,
      :on_delete=>:cascade,
      :on_update=>:cascade
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
      :local_dependencies => [:direction,:display_name]
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
