lambda__segment_module_branches =
  lambda do|args|
  ret = {
    model_name: :module_branch,
    convert: true,
    join_type: :inner,
    join_cond: { service_id: :service_module__id },
    cols: args[:cols]
  }
  ret[:filter] = args[:filter] if args[:filter]
  ret
end
lambda__segment_namespace =
  lambda do|args|
  ret = {
    model_name: :namespace,
    convert: true,
    join_type: :inner,
    join_cond: { id: :service_module__namespace_id },
    cols: args[:cols]
  }
  ret
end
lambda__segment_repos =
  lambda do|args|
  {
    model_name: :repo,
    convert: true,
    join_type: :inner,
    join_cond: { id: :module_branch__repo_id },
    cols: args[:cols]
  }
end
lambda__segment_remote_repos =
  lambda do|args|
  {
    model_name: :repo_remote,
    convert: true,
    join_type: args[:join_type] || :left_outer,
    join_cond: { repo_id: :repo__id },
    cols: args[:cols]
  }
end
lambda__segment_impls =
  lambda do|args|
  {
    model_name: :implementation,
    convert: true,
    join_type: :inner,
    join_cond: { repo_id: :module_branch__repo_id },
    cols: args[:cols]
  }
end
assembly_nodes  =
  [
   lambda__segment_module_branches.call(cols: [:id]),
   {
     model_name: :component,
     alias: :assembly,
     convert: true,
     join_type: :inner,
     join_cond: { module_branch_id: :module_branch__id },
     cols: [:id, :group_id, :display_name]
   },
   {
     model_name: :node,
     convert: true,
     join_type: :inner,
     join_cond: { assembly_id: :assembly__id },
     cols: [:id, :group_id, :display_name]
   }
  ]

{
  schema: :module,
  table: :service,
  columns: {
    dsl_parsed: { type: :boolean, default: false }, #set to true when dsl has successfully parsed
    namespace_id: {
      type: :bigint,
      foreign_key_rel_type: :namespace,
      on_delete: :set_null,
      on_update: :set_null
    }
  },
  virtual_columns: {
    module_branches: {
      type: :json,
      hidden: true,
      remote_dependencies: [lambda__segment_module_branches.call(cols: ModuleBranch.common_columns())]
    },
    namespace: {
      type: :json,
      hidden: true,
      remote_dependencies: [lambda__segment_namespace.call(cols: Namespace.common_columns())]
    },
    workspace_info: {
      type: :json,
      hidden: true,
      remote_dependencies:       [lambda__segment_module_branches.call(cols: [:id, :display_name, :group_id, :branch, :version, :current_sha, :repo_id], filter: [:eq, :is_workspace, true]),
                                  lambda__segment_repos.call(cols: [:id, :display_name, :group_id, :repo_name, :local_dir, :remote_repo_name])]
    },
    workspace_info_full: {
      type: :json,
      hidden: true,
      remote_dependencies:       [lambda__segment_module_branches.call(cols: [:id, :display_name, :group_id, :branch, :version, :current_sha, :repo_id], filter: [:eq, :is_workspace, true]),
                                  lambda__segment_repos.call(cols: [:id, :display_name, :group_id, :repo_name, :local_dir, :remote_repo_name]),
                                  lambda__segment_remote_repos.call(cols: [:id, :display_name, :group_id, :ref, :repo_name, :repo_namespace, :created_at, :repo_id, :is_default], join_type: :left_outer)
     ]
    },
    version_info: {
      type: :json,
      hidden: true,
      remote_dependencies: [lambda__segment_module_branches.call(cols: [:version])]
    },
    # MOD_RESTRUCT: deprecate below for above
    library_repo: {
      type: :json,
      hidden: true,
      remote_dependencies:       [lambda__segment_module_branches.call(cols: [:id, :repo_id], filter: [:eq, :is_workspace, false]),
                                  lambda__segment_repos.call(cols: [:id, :display_name, :group_id, :repo_name, :local_dir, :remote_repo_name])]
    },
    repos: {
      type: :json,
      hidden: true,
      remote_dependencies:       [lambda__segment_module_branches.call(cols: [:id, :repo_id]),
                                  lambda__segment_repos.call(cols: [:id, :display_name, :group_id, :repo_name, :local_dir, :remote_repo_name])]
    },
    remote_repos: {
      type: :json,
      hidden: true,
      remote_dependencies:       [lambda__segment_module_branches.call(cols: [:id, :repo_id, :version]),
                                  lambda__segment_repos.call(cols: [:id, :repo_name, :local_dir]),
                                  lambda__segment_remote_repos.call(cols: [:id, :display_name, :group_id, :ref, :repo_name, :repo_namespace, :repo_id, :created_at, :is_default])
     ]
    },
    module_branches_with_repos: {
      type: :json,
      hidden: true,
      remote_dependencies:       [lambda__segment_module_branches.call(cols: [:id, :repo_id, :version, :dsl_parsed]),
                                  lambda__segment_repos.call(cols: [:id, :repo_name, :local_dir])
     ]
    },
    # TODO: not sure if we haev implementations on service modules
    implementations: {
      type: :json,
      hidden: true,
      remote_dependencies:       [lambda__segment_module_branches.call(cols: [:id, :repo_id]),
                                  lambda__segment_impls.call(cols: [:id, :display_name, :group_id])]
    },
    assemblies: {
      type: :json,
      hidden: true,
      remote_dependencies:       [
       lambda__segment_module_branches.call(cols: [:id]),
       {
         model_name: :component,
         convert: true,
         join_type: :inner,
         join_cond: { module_branch_id: :module_branch__id },
         cols: [:id, :group_id, :display_name]
       }]
    },
    assembly_nodes: {
      type: :json,
      hidden: true,
      remote_dependencies: assembly_nodes
     },
    component_refs: {
      type: :json,
      hidden: true,
      remote_dependencies:        assembly_nodes +
       [{
          model_name: :component_ref,
          convert: true,
          join_type: :inner,
          join_cond: { node_node_id: q(:node, :id) },
          cols: [:id, :group_id, :display_name, :component_type, :version, :has_override_version, :component_template_id]
        }]
    },
    task_templates: {
      type: :json,
      hidden: true,
      remote_dependencies: [{
        model_name: :task_template,
        convert: true,
        join_type: :inner,
        join_cond: { module_service_id: :service_module__id },
        cols: [:id, :ref, :group_id, :ancestor_id, :display_name, :task_action, :content, :component_component_id, :module_service_id]
      }]
    }
  },
  many_to_one: [:project, :library], #MOD_RESTRUCT: may remove library as parent
  one_to_many: [:module_branch, :task_template]
}
