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
lambda__segment_remote_repos =
  lambda{|args|
  {
    :model_name=>:repo_remote,
    :convert => true,
    :join_type=>:inner,
    :join_cond=>{:repo_id =>:repo__id},
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
assembly_nodes  = 
  [
   lambda__segment_module_branches.call(:cols => [:id]),
   {
     :model_name=>:component,
     :alias => :assembly,
     :convert => true,
     :join_type=>:inner,
     :join_cond=>{:module_branch_id =>:module_branch__id},
     :cols=>[:id,:group_id,:display_name]
   },
   {
     :model_name=>:node,
     :convert => true,
     :join_type=>:inner,
         :join_cond=>{:assembly_id =>:assembly__id},
     :cols=>[:id,:group_id,:display_name]
   }
  ]


{
  :schema=>:module,
  :table=>:service,
  :columns=>{
    :dsl_parsed => {:type=>:boolean,:default=>false}, #set to true when dsl has successfully parsed
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
    :workspace_info_full=>{
      :type=>:json,
      :hidden=>true,
      :remote_dependencies=>
      [lambda__segment_module_branches.call(:cols =>[:id,:display_name,:group_id,:branch,:version,:current_sha,:repo_id],:filter=>[:eq,:is_workspace,true]),
       lambda__segment_repos.call(:cols=>[:id,:display_name,:group_id,:repo_name,:local_dir,:remote_repo_name]),
       lambda__segment_remote_repos.call(:cols => [:id,:display_name,:group_id,:ref,:repo_name,:repo_namespace,:created_at,:repo_id])
     ]
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
      [lambda__segment_module_branches.call(:cols =>[:id,:repo_id]),
       lambda__segment_repos.call(:cols=>[:id,:display_name,:group_id,:repo_name,:local_dir,:remote_repo_name])]
    },
    #TODO: not sure if we haev implementations on service modules
    :implementations=>{
      :type=>:json,
      :hidden=>true,
      :remote_dependencies=>
      [lambda__segment_module_branches.call(:cols => [:id,:repo_id]),
       lambda__segment_impls.call(:cols => [:id,:display_name,:group_id])]
    },
    :assemblies=>{
      :type=>:json,
      :hidden=>true,
      :remote_dependencies=>
      [
       lambda__segment_module_branches.call(:cols => [:id]),
       {
         :model_name=>:component,
         :convert => true,
         :join_type=>:inner,
         :join_cond=>{:module_branch_id =>:module_branch__id},
         :cols=>[:id,:group_id,:display_name]
       }]
    },
    :assembly_nodes=>{
      :type=>:json,
      :hidden=>true,
      :remote_dependencies=>assembly_nodes
     },
     :component_refs=>{
      :type=>:json,
      :hidden=>true,
      :remote_dependencies=>
       assembly_nodes +
       [{
          :model_name => :component_ref,
          :convert => true,
          :join_type => :inner,
          :join_cond=>{:node_node_id => q(:node,:id)},
          :cols => [:id,:group_id,:display_name,:component_type,:version,:has_override_version,:component_template_id]
        }]
     }
  },
  :many_to_one=>[:project,:library], #MOD_RESTRUCT: may remove library as parent
  :one_to_many=>[:module_branch]
}
