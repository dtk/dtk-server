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
    #TODO: assembly_id seems to be redundant with component as parent
    :assembly_id=>{
      :type=>:bigint,
      :foreign_key_rel_type=>:component,
      :on_delete=>:cascade,
      :on_update=>:cascade
    }
  },
#  :many_to_one=>[:library, :datacenter, :component, :service_add_on]
  :many_to_one=>[:library, :datacenter, :component]
}
