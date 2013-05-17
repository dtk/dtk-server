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
  ret={
    :model_name=>:implementation,
    :convert => true,
    :join_type=>:inner,
    :join_cond=>{:repo_id =>:module_branch__repo_id},
    :cols=>args[:cols]
  }
  ret[:filter] = args[:filter] if args[:filter]
  ret[:alias] = args[:alias] if args[:alias]
  ret
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
    :dsl_parsed => {:type=>:boolean,:default=>false} # set to true if dsl has successfully parsed
  },
  :virtual_columns=>{
    :module_branches=>{
      :type=>:json,
      :hidden=>true,
      :remote_dependencies=>[lambda__segment_module_branches.call(:cols => [:id,:display_name,:group_id,:branch,:version,:type,:repo_id,:is_workspace])]
    },
    :workspace_info=>{
      :type=>:json,
      :hidden=>true,
      :remote_dependencies=>
      [lambda__segment_module_branches.call(:cols =>[:id,:display_name,:group_id,:branch,:version,:current_sha,:repo_id],:filter=>[:eq,:is_workspace,true]),
       lambda__segment_repos.call(:cols=>[:id,:display_name,:group_id,:repo_name,:local_dir,:remote_repo_name])]
    },
    :version_info=>{
      :type=>:json,
      :hidden=>true,
      :remote_dependencies=>[lambda__segment_module_branches.call(:cols => [:version])]
    },
    #MOD_RESTRUCT: deprecate below for above
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
      [lambda__segment_module_branches.call(:cols => [:id,:repo_id]),
       lambda__segment_repos.call(:cols => [:id,:display_name,:group_id,:repo_name,:local_dir,:remote_repo_name])]
    },
    :implementations=>{
      :type=>:json,
      :hidden=>true,
      :remote_dependencies=>
      [lambda__segment_module_branches.call(:cols => [:id,:repo_id]),
       lambda__segment_impls.call(:cols => [:id,:display_name,:group_id,:repo,:branch])]
    },
    :library_implementations=>{
      :type=>:json,
      :hidden=>true,
      :remote_dependencies=>
      [lambda__segment_module_branches.call(:cols => [:id,:repo_id]),
       lambda__segment_impls.call(
         :cols => [:id,:display_name,:group_id,:repo,:branch],
         :alias => :library_implementation,
         :filter => [:neq,:library_library_id,nil])
      ]
    },
    :components=>{
      :type=>:json,
      :hidden=>true,
      :remote_dependencies=>
      [lambda__segment_module_branches.call(:cols => [:id,:version],:filter=>[:eq,:is_workspace,true]),
       lambda__segment_components.call(
        :cols => [:id,:display_name,:version],
        :filter=>[:eq,:assembly_id,nil])
      ]
    },
    :assembly_templates=>{
      :type=>:json,
      :hidden=>true,
      :remote_dependencies=>
      [lambda__segment_module_branches.call(:cols => [:id]),
       lambda__segment_components.call(
        :cols => [:id,:display_name,:group_id,:component_type,:version],
        :alias=>:component_template,
        :filter=>[:eq,:node_node_id,nil]),
       {
         :model_name=>:component_ref,
         :convert => true,
         :join_type=>:inner,
         :join_cond=>{:component_template_id =>:component_template__id},
         :cols=>[:id,:display_name,:group_id,:node_node_id,:component_template_id,:component_type,:version]
       },
       {
         :model_name=>:node,
         :join_type=>:inner,
         :join_cond=>{:id =>:component_ref__node_node_id},
         :cols=>[:id,:display_name,:group_id,:assembly_id]
       },
       {
         :model_name=>:component,
         :alias => :assembly_template,
         :convert => true,
         :join_type=>:inner,
         :join_cond=>{:id =>:node__assembly_id},
         :cols=>[:id,:display_name,:group_id,:module_branch_id,:component_type]
       }]
    },
    :component_instances=>{
      :type=>:json,
      :hidden=>true,
      :remote_dependencies=>
      [lambda__segment_module_branches.call(:cols => [:id]),
       lambda__segment_components.call(
        :cols => [:id,:group_id,:display_name,:component_type,:version],
        :filter=>[:neq,:node_node_id,nil])
      ]
    }
  },
  :many_to_one=>[:project,:library], #MOD_RESTRUCT: may remove library as parent
  :one_to_many=>[:module_branch]
}
