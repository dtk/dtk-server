lambda__segment_module_branches =
  lambda{|*params|
  mb_cols = params[0]
  optional_filter = params[1]
  ret = {
    :model_name=>:module_branch,
    :convert => true,
    :join_type=>:inner,
    :join_cond=>{:component_id =>:component_module__id},
    :cols=>mb_cols
  }
  ret[:filter] = optional_filter if optional_filter
  ret
}
lambda__segment_repos =
  lambda{|cols|
  {
    :model_name=>:repo,
    :convert => true,
    :join_type=>:inner,
    :join_cond=>{:id =>:module_branch__repo_id},
    :cols=>cols
  }
}

{
  :schema=>:module,
  :table=>:component,
  :columns=>{
    :remote_repo => {:type=>:varchar, :size => 100} #non null if points to remote component module
  },
  :virtual_columns=>{
    :repos=>{
      :type=>:json,
      :hidden=>true,
      :remote_dependencies=>
      [lambda__segment_module_branches.call([:id,:repo_id]),
       lambda__segment_repos.call([:id,:display_name,:repo_name,:local_dir,:remote_repo_name])]
    }
  },
  :many_to_one=>[:library],
  :one_to_many=>[:module_branch]
}
