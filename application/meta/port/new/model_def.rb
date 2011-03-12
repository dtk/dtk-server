{
  :schema=>:port,
  :table=>:port,
  :columns=>{
    :type=>{
      :type=>:varchar,
      :size =>25
    },
    :port_direction=>{
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
  :many_to_one=>[:node]
}
