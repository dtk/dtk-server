{
  :schema=>:module,
  :table=>:service,
  :columns=>{
    :remote_repo => {:type=>:varchar, :size => 100} #non null if points to remote service module
  },
  :virtual_columns=>{
    :module_branches=>{
      :type=>:json,
      :hidden=>true,
      :remote_dependencies=>
      [{
         :model_name=>:module_branch,
         :convert => true,
         :join_type=>:inner,
         :join_cond=>{:service_id =>:service_module__id},
         :cols=>[:id,:display_name,:branch,:version,:type,:repo_id]
       }]
    }
  },
  :many_to_one=>[:library],
  :one_to_many=>[:module_branch]
}
