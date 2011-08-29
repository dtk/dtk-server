{
  :schema=>:link_def,
  :table=>:posible_link,
  :columns=>{
    :position => {:type =>:integer},
    :internal_external => {:type=>:varchar, :size => 15}, #internal || external || either
  },
  :many_to_one=>[:link_def],
  :one_to_many=>[:link_def_event,:link_def_attribute_mapping]
}

