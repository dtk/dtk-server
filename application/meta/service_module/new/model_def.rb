{
  :schema=>:module,
  :table=>:service,
  :columns=>{
    :remote_repo => {:type=>:varchar, :size => 100} #non null if points to remote service module
  },
  :many_to_one=>[:library],
  :one_to_many=>[:sm_branch]
}
