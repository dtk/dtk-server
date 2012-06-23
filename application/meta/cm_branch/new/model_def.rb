{
  :schema=>:module,
  :table=>:component_branch,
  :columns=>{
    :branch => {:type=>:varchar, :size => 50, :default => "master"}, 
    :version => {:type=>:varchar, :size => 20},
    :is_workspace => {:type =>:boolean}
  },
  :many_to_one=>[:component_module]
}
