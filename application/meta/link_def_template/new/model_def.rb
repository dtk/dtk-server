{
  :schema=>:link_def,
  :table=>:template,
  :columns=>{
    :possible_links => {:type =>:json}
  },
  :many_to_one=>[:component]
}

