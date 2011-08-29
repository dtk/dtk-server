{
  :schema=>:link_def,
  :table=>:posible_link,
  :columns=>{
    :position => {:type =>:integer},
    :remote_component_id => {
      :type=>:bigint,
      :foreign_key_rel_type=>:component,
      :on_delete=>:cascade,
      :on_update=>:cascade
    },
    :internal_external => {:type=>:varchar, :size => 10}, #internal || external || either
  },
  :many_to_one=>[:link_def],
  :one_to_many=>[:link_def_event,:link_def_attribute_mapping]
}

