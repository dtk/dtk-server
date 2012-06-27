{
  :schema=>:module,
  :table=>:component,
  :columns=>{
    :remote_repo => {:type=>:varchar, :size => 100} #non null if points to remote component module
  },
  :many_to_one=>[:library],
  :one_to_many=>[:module_branch]
}
