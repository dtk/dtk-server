{
  :schema=>:module,
  :table=>:module_ref_lock,
  :columns=>{
    :assemby_id=>{
      :type=>:bigint,
      :foreign_key_rel_type=>:attribute,
      :on_delete=>:cascade,
      :on_update=>:cascade
    },
    :info=>{:type=>:json},
    :locked_branch_sha=>{:type=>:varchar,:size => 50},
  },
  :many_to_one => [:component_module]
}
