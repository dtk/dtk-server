{
  :schema=>:link_def,
  :table=>:remote_component,
  :columns=>{
    :local_component_type => {:type=>:varchar, :size => 50},
    :link_def_type => {:type=>:varchar, :size =>  50}
  },
  :many_to_one=>[:component]
}

