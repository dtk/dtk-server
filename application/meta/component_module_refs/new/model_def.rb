{
  :schema=>:module,
  :table=>:component_module_refs,
  :columns=>{
    :content=>{:type => :json}
  },
  :many_to_one => [:module_branch]
}
