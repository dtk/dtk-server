{
  :schema=>:state,
  :table=>:state_change,
  :columns=>{
    :status=>{:type=>:varchar, :default=>"pending", :size=>15},
    :type=>{:type=>:varchar, :size=>25},
    :object_type=>{:type=>:varchar, :size=>15},
    :base_object=>{:type=>:json},
    :change=>{:type=>:json},
    :attribute_id=>{
      :type=>:bigint,
      :foreign_key_rel_type=>:attribute,
      :on_delete=>:cascade,
      :on_update=>:cascade
    },
    :ancestor_id=>{
      :type=>:bigint,
      :foreign_key_rel_type=>:state_change,
      :on_delete=>:set_null,
      :on_update=>:set_null
    },
    :node_id=>{
      :type=>:bigint,
      :foreign_key_rel_type=>:node,
      :on_delete=>:cascade,
      :on_update=>:cascade
    },
    :component_id=>{
      :type=>:bigint,
      :foreign_key_rel_type=>:component,
      :on_delete=>:cascade,
      :on_update=>:cascade
    }
  },
  :many_to_one=>[:datacenter, :state_change],
  :one_to_many=>[:state_change]
}
