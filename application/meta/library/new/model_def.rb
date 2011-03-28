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
   :node_group,
   :node_group_member,
   :attribute_link,
   :port_link,
   :network_partition,
   :network_gateway,
   :region,
   :assoc_region_network,
   :data_source,
   :search_object,
   :constraints,
   :component_relation
  ]
}
