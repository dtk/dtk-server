lambda__segment_module_branches =
  lambda{|args|
  ret = {
    :model_name=>:module_branch,
    :convert => true,
    :join_type=>:inner,
    :join_cond=>{:test_id =>:test_module__id},
    :cols=>args[:cols]
  }
  ret[:filter] = args[:filter] if args[:filter]
  ret
}
lambda__segment_namespace =
  lambda{|args|
  ret = {
    :model_name=>:namespace,
    :convert => true,
    :join_type=>:inner,
    :join_cond=>{:id =>:namespace__id},
    :cols=>args[:cols]
  }
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
lambda__segment_instances =
  lambda{|args|
  ret = {
    :model_name=>:component,
    :convert => true,
    :join_type=>:inner,
    :alias => :component_instance,
    :join_cond=>{:ancestor_id =>:component__id},
    :cols=>args[:cols]
  }

  ret[:filter] = args[:filter] if args[:filter]
  ret[:alias] = args[:alias] if args[:alias]
  ret
}

lambda__segment_assembly =
  lambda{|args|
  ret = {
    :model_name=>:component,
    :convert => true,
    :join_type=>:inner,
    :alias => :assembly,
    :join_cond=>{:id =>:component_instance__assembly_id},
    :cols=>args[:cols]
  }

  ret[:filter] = args[:filter] if args[:filter]
  ret[:alias] = args[:alias] if args[:alias]
  ret
}

lambda__segment_node =
  lambda{|args|
  ret = {
    :model_name=>:node,
    :convert => true,
    :join_type=>:inner,
    :alias => :node,
    :join_cond=>{:id =>:component_instance__node_node_id},
    :cols=>args[:cols]
  }

  ret[:filter] = args[:filter] if args[:filter]
  ret[:alias] = args[:alias] if args[:alias]
  ret
}

lambda__segment_attributes =
  lambda{|args|
  ret = {
    :model_name=>:attribute,
    :convert => true,
    :join_type=>:inner,
    :join_cond=>{:component_component_id => :component__id},
    :cols=>args[:cols]
  }
  ret[:filter] = args[:filter] if args[:filter]
  ret[:alias] = args[:alias] if args[:alias]
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
    :join_type=>args[:join_type]||:inner,
    :join_cond=>{:repo_id =>:repo__id},
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
{
  :schema=>:module,
  :table=>:test,
  :columns=>{
    :dsl_parsed => {:type=>:boolean,:default=>false}, # set to true if dsl has successfully parsed
    :namespace_id=>{
      :type=>:bigint,
      :foreign_key_rel_type=>:namespace,
      :on_delete=>:set_null,
      :on_update=>:set_null
    }
  },
  :virtual_columns=>{
    :namespace=>{
      :type => :json,
      :hidden => true,
      :remote_dependencies=>[lambda__segment_namespace.call(:cols => Namespace.common_columns())]
    },
    :module_branches=>{
      :type=>:json,
      :hidden=>true,
      :remote_dependencies=>[lambda__segment_module_branches.call(:cols => ModuleBranch.common_columns())]
    },
    :workspace_info=>{
      :type=>:json,
      :hidden=>true,
      :remote_dependencies=>
      [lambda__segment_module_branches.call(:cols => ModuleBranch.common_columns(),:filter=>[:eq,:is_workspace,true]),
       lambda__segment_repos.call(:cols=>[:id,:display_name,:group_id,:repo_name,:local_dir,:remote_repo_name])]
    },
    :workspace_info_full=>{
      :type=>:json,
      :hidden=>true,
      :remote_dependencies=>
      [lambda__segment_module_branches.call(:cols => ModuleBranch.common_columns(), :filter=>[:eq,:is_workspace,true]),
       lambda__segment_repos.call(:cols=>[:id,:display_name,:group_id,:repo_name,:local_dir,:remote_repo_name]),
       lambda__segment_remote_repos.call(:cols => [:id,:display_name,:group_id,:ref,:repo_name,:repo_namespace,:created_at,:repo_id,:is_default],:join_type=>:left_outer)
     ]
    },
    :version_info=>{
      :type=>:json,
      :hidden=>true,
      :remote_dependencies=>[lambda__segment_module_branches.call(:cols => [:version])]
    },
    # MOD_RESTRUCT: deprecate below for above
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
       lambda__segment_repos.call(:cols => [:id,:display_name,:group_id,:repo_name,:local_dir,:remote_repo_name,:remote_repo_namespace])]
    },
    :remote_repos=>{
      :type=>:json,
      :hidden=>true,
      :remote_dependencies=>
      [lambda__segment_module_branches.call(:cols => [:id,:repo_id,:version,:external_ref]),
       lambda__segment_repos.call(:cols => [:id,:repo_name,:local_dir, :remote_repo_namespace]),
       lambda__segment_remote_repos.call(:cols => [:id,:display_name,:group_id,:ref,:repo_name,:repo_namespace,:repo_id,:created_at,:is_default])
     ]
    },
    :module_branches_with_repos=>{
      :type=>:json,
      :hidden=>true,
      :remote_dependencies=>
      [lambda__segment_module_branches.call(:cols => [:id,:repo_id,:version,:external_ref]),
       lambda__segment_repos.call(:cols => [:id,:repo_name,:local_dir,:remote_repo_namespace])
     ]
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
        :cols => [:id,:display_name,:group_id,:version,:component_type],
        :filter=>[:eq,:assembly_id,nil])
      ]
    },
    :attributes=>{
      :type=>:json,
      :hidden=>true,
      :remote_dependencies=>
      [lambda__segment_module_branches.call(:cols => [:id, :version],:filter=>[:eq,:is_workspace,true]),
       lambda__segment_components.call(:cols => [:id, :display_name],:filter=>[:eq,:assembly_id,nil]),
       lambda__segment_attributes.call(:cols => [:id,:display_name,:value_asserted,:external_ref])
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
         :convert => true,
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
        :cols => [:id,:group_id,:display_name,:component_type,:version,:assembly_id,:project_project_id,:component_template_id,:locked_sha],
        :filter=>[:neq,:node_node_id,nil])
      ]
    },
    :component_module_instances_node=>{
      :type=>:json,
      :hidden=>true,
      :remote_dependencies=>
      [
        lambda__segment_module_branches.call(:cols => [:id]),
        lambda__segment_components.call(
          :cols => [:id],
          :filter=>[:eq,:type,'template']),
        lambda__segment_instances.call(
          :cols => [:id,:group_id,:display_name,:component_type,:version,:assembly_id,:ancestor_id,:node_node_id],
          :filter=>[:eq,:assembly_id,nil]),
        lambda__segment_node.call(
          :cols => [:id,:display_name])
      ]
    },
    :component_module_instances_assemblies=>{
      :type=>:json,
      :hidden=>true,
      :remote_dependencies=>
      [
        lambda__segment_module_branches.call(:cols => [:id]),
        lambda__segment_components.call(
          :cols => [:id],
          :filter=>[:eq,:type,'template']),
        lambda__segment_instances.call(
          :cols => [:id,:group_id,:display_name,:component_type,:version,:assembly_id,:ancestor_id,:node_node_id],
          :filter=>[:neq,:node_node_id,nil]),
        lambda__segment_assembly.call(
          :cols => [:id,:display_name]),
        lambda__segment_node.call(
          :cols => [:id,:display_name])
      ]
    }
  },
  :many_to_one=>[:project,:library], #MOD_RESTRUCT: may remove library as parent
  :one_to_many=>[:module_branch]
}
