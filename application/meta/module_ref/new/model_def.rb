{
  schema: :module,
  table: :module_ref,
  columns: {
    module_name: { type: :varchar, size: 50 },
    module_type: { type: :varchar, size: 25 },
    version_info: { type: :json },
    namespace_info: { type: :json },
    external_ref: { type: :json }
  },
  virtual_columns: {
    is_dependency_to_component_modules: {
      type: :json,
      hidden: true,
      remote_dependencies:
      [
        {
          model_name: :module_branch,
          convert: true,
          join_type: :inner,
          join_cond: { id: :module_ref__branch_id },
          cols: [:id, :display_name, :branch, :version, :component_id]
         },
        {
          model_name: :component_module,
          convert: true,
          join_type: :inner,
          join_cond: { id: :module_branch__component_id },
          cols: [:id, :display_name, :namespace_id]
        },
        {
          model_name: :namespace,
          convert: true,
          join_type: :inner,
          join_cond: { id: :component_module__namespace_id },
          cols: [:id, :display_name]
        }
      ]
    },
    is_dependency_to_service_modules: {
      type: :json,
      hidden: true,
      remote_dependencies:
      [
        {
          model_name: :module_branch,
          convert: true,
          join_type: :inner,
          join_cond: { id: :module_ref__branch_id },
          cols: [:id, :display_name, :branch, :version, :service_id]
         },
        {
          model_name: :service_module,
          convert: true,
          join_type: :inner,
          join_cond: { id: :module_branch__service_id },
          cols: [:id, :display_name, :namespace_id]
        },
        {
          model_name: :namespace,
          convert: true,
          join_type: :inner,
          join_cond: { id: :service_module__namespace_id },
          cols: [:id, :display_name]
        }
      ]
    }
  },
  many_to_one: [:module_branch]
}
         # join_cond: { node_node_id: :node__id, component_type: :nested_component__component_type },