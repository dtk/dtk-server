{
  :schema=>:library,
  :table=>:library,
  :columns=>{
    :ancestor_id=>{
      :type=>:bigint,
      :foreign_key_rel_type=>:library,
      :on_delete=>:set_null,
      :on_update=>:set_null
    }
  },
  :virtual_columns=>{},
  :many_to_one=>[],
  :one_to_many=>
  [
   :component,
   :node,
   :node_binding_ruleset,
   :node_group_relation,
   :attribute_link,
   :port_link, #MOD_RESTRUCT: may remove
   :network_partition,
   :network_gateway,
   :region,
   :assoc_region_network,
   :data_source,
   :constraints,
   :component_relation,
   :implementation,
   :component_module,#MOD_RESTRUCT: may remove
   :service_module, #MOD_RESTRUCT: may remove
   :test_module #MOD_RESTRUCT: may remove
  ]
}
