{
  schema: :node,
  table: :group_relation,
  columns: {
    node_id: {
      type: :bigint,
      foreign_key_rel_type: :node,
      on_delete: :cascade,
      on_update: :cascade
    },
    node_group_id: {
      type: :bigint,
      foreign_key_rel_type: :node,
      on_delete: :cascade,
      on_update: :cascade
    }
  },
  many_to_one: [:datacenter,:library],
  virtual_columns: {
    service_node_group: {
      type: :json,
      hidden: true,
      remote_dependencies: [{
          model_name: :node,
          alias: :service_node_group,
          convert: true,
          join_type: :inner,
          join_cond: {id: :node_group_relation__node_group_id},
          cols: [:id,:group_id,:display_name,:type]
       }]
    },
    target_ref: {
      type: :json,
      hidden: true,
      remote_dependencies: [{
          model_name: :node,
          alias: :target_ref,
          convert: true,
          join_type: :inner,
          join_cond: {id: :node_group_relation__node_id},
          cols: [:id,:group_id,:display_name,:type,:external_ref]
       }]
    },
    target_refs_with_links: {
      type: :json,
      hidden: true,
      remote_dependencies: [{
          model_name: :node,
          alias: :target_ref,
          convert: true,
          join_type: :inner,
          join_cond: {id: :node_group_relation__node_id},
          cols: [:id,:group_id,:display_name,:type,:external_ref]
       },
       {
          model_name: :node_group_relation,
          alias: :link,
          join_type: :inner,
          convert: true,
          join_cond: {node_id: :node_group_relation__node_id},
          cols: [:id,:group_id,:node_id,:node_group_id]
       }]
    },
    node_member_assembly: {
      type: :json,
      hidden: true,
      remote_dependencies: [{
          model_name: :node,
          alias: :node_group,
          convert: true,
          join_type: :inner,
          join_cond: {id: :node_group_relation__node_group_id},
          cols: [:id,:group_id,:display_name,:type,:assembly_id]
        },
        {
          model_name: :component,
          alias: :assembly,
          join_type: :inner,
          convert: true,
          join_cond: {id: :node_group__assembly_id},
          cols: [:id,:group_id,:display_name]
        }]
    }
  }
}
