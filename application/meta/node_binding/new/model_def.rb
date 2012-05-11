{
  :schema=>:node,
  :table=>:binding,
  :columns=>{
    :conditional => {:type=>:json},
    :node_template_id=>{
      :type=>:bigint,
      :foreign_key_rel_type=>:node,
      :on_delete=>:set_cascade,
      :on_update=>:set_cascade
    }
  },
  :many_to_one=>[:library,:node_binding],
  :one_to_many => [:node_binding]
}

