{
  schema: :service,
  table: :node_binding,
  columns: {
    assembly_node_id: {
      type: :bigint,
      foreign_key_rel_type: :node,
      on_delete: :cascade,
      on_update: :cascade
    },
    sub_assembly_node_id: {
      type: :bigint,
      foreign_key_rel_type: :node,
      on_delete: :cascade,
      on_update: :cascade
    }
  },
  many_to_one: [:service_add_on] 
}
