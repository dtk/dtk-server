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
    #TODO: assembly id seems redundant with component
    :assembly_id=>{
      :type=>:bigint,
      :foreign_key_rel_type=>:component,
      :on_delete=>:cascade,
      :on_update=>:cascade
    },
    :output_is_local=>{:type=>:boolean} #used when this is on service_add_on parent
  },
#  :many_to_one=>[:library, :datacenter, :component, :service_add_on]
  :many_to_one=>[:library, :datacenter, :component]
}
