{
  :schema=>:module,
  :table=>:module_ref,
  :columns=>{
    :module_name=>{:type => :varchar, :size => 50},
    :module_type=>{:type => :varchar, :size => 25},
    :version_info=>{:type => :json},
    :namespace_info=>{:type => :json}
  },
  :many_to_one => [:module_branch]
}
