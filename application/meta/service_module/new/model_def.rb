lambda__segment_module_branches =
  lambda{|args|
  ret = {
    :model_name=>:module_branch,
    :convert => true,
    :join_type=>:inner,
    :join_cond=>{:service_id =>:service_module__id},
    :cols=>args[:cols]
  }
  ret[:filter] = args[:filter] if args[:filter]
  ret
}
lambda__segment_repos =
  lambda{|args|
  {
    :model_name=>:repo,
    :convert => true,
    :join_type=>:inner,
    :join_cond=>{:id =>:module_branch__repo_id},
    :cols=>args[:cols]
  }
}
lambda__segment_impls =
  lambda{|args|
  {
    :model_name=>:implementation,
    :convert => true,
    :join_type=>:inner,
    :join_cond=>{:repo_id =>:module_branch__repo_id},
    :cols=>args[:cols]
  }
}
{
  :schema=>:module,
  :table=>:service,
  :virtual_columns=>{
    :module_branches=>{
      :type=>:json,
      :hidden=>true,
      :remote_dependencies=>[lambda__segment_module_branches.call(:cols => [:id,:display_name,:branch,:version,:type,:repo_id])]
    },
    :library_repo=>{
      :type=>:json,
      :hidden=>true,
      :remote_dependencies=>
      [lambda__segment_module_branches.call(:cols =>[:id,:repo_id],:filter=>[:eq,:is_workspace,false]),
       lambda__segment_repos.call(:cols=>[:id,:display_name,:group_id,:repo_name,:local_dir,:remote_repo_name])]
    },
    :repos=>{
      :type=>:json,
      :hidden=>true,
      :remote_dependencies=>
      [lambda__segment_module_branches.call(:cols =>[:id,:repo_id]),
       lambda__segment_repos.call(:cols=>[:id,:display_name,:group_id,:repo_name,:local_dir,:remote_repo_name])]
    },
    :implementations=>{
      :type=>:json,
      :hidden=>true,
      :remote_dependencies=>
      [lambda__segment_module_branches.call(:cols => [:id,:repo_id]),
       lambda__segment_impls.call(:cols => [:id,:display_name])]
    }
  },
  :many_to_one=>[:library],
  :one_to_many=>[:module_branch]
}
