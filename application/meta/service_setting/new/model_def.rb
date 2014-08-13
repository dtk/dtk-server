{
  :schema=>:service,
  :table=>:setting,
  :columns=>{
    # :assembly_id=>{ #non-null if branch for an assembly instance
    #   :type=>:bigint,
    #   :foreign_key_rel_type=>:component,
    #   :on_delete=>:cascade,
    #   :on_update=>:cascade
    # },
    :node_bindings=>{:type => :json},
    :attribute_settings=>{:type => :json}
  },
  :virtual_columns=>{},
  :many_to_one => [:component] 
}