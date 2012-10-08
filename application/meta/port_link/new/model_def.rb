{
  :schema=>:port,
  :table=>:link,
  :columns=>{
    :input_id=>{
      :type=>:bigint,
      :foreign_key_rel_type=>:port,
      :on_delete=>:cascade,
      :on_update=>:cascade
    },
    :output_id=>{
      :type=>:bigint,
      :foreign_key_rel_type=>:port,
      :on_delete=>:cascade,
      :on_update=>:cascade
    },
    #TODO: assembly id may be redundant with component; if so remove
    :assembly_id=>{
      :type=>:bigint,
      :foreign_key_rel_type=>:component,
      :on_delete=>:cascade,
      :on_update=>:cascade
    },
    #these two used when parent is service_add_on
    :required=>{:type=>:boolean}, 
    :output_is_local=>{:type=>:boolean} 
  },
  :many_to_one=>[:library, :datacenter, :component, :service_add_on]
}
