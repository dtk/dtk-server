lambda__segment_module_branches =
  lambda{|args|
  ret = {
    :model_name=>:module_branch,
    :convert => true,
    :join_type=>:inner,
    :join_cond=>{:component_id =>:component_module__id},
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
    :join_cond=>{:id =>:module_branch__repo_id},
    :cols=>args[:cols]
  }
}
lambda__segment_components =
  lambda{|args|
  ret = {
    :model_name=>:component,
    :convert => true,
    :join_type=>:inner,
    :join_cond=>{:module_branch_id =>:module_branch__id},
    :cols=>args[:cols]
  }
  ret[:filter] = args[:filter] if args[:filter]
  ret[:alias] = args[:alias] if args[:alias]
  ret
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
      [lambda__segment_module_branches.call(:cols => [:id,:repo_id]),
       lambda__segment_repos.call(:cols => [:id,:display_name,:repo_name,:local_dir,:remote_repo_name])]
    },
    :implementations=>{
      :type=>:json,
      :hidden=>true,
      :remote_dependencies=>
      [lambda__segment_module_branches.call(:cols => [:id,:repo_id]),
       lambda__segment_impls.call(:cols => [:id,:display_name])]
    },
    :target_instances=>{
      :type=>:json,
      :hidden=>true,
      :remote_dependencies=>
      [lambda__segment_module_branches.call(:cols => [:id]),
       lambda__segment_components.call(
        :cols => [:id,:display_name],
        :alias=>:target_instance,
        :filter=>[:neq,:node_node_id,nil])]
    }
  },
  :many_to_one=>[:library],
  :one_to_many=>[:module_branch]
}
