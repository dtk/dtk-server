{
  schema: :violation,
  table: :violation,
  columns: {
    severity: { type: :varchar, size: 20 }, # error || warning || ..
    expression: { type: :json },
    target_node_id: {
      type: :bigint,
      foreign_key_rel_type: :node,
      on_delete: :cascade,
      on_update: :cascade
    }
  },
  many_to_one: [:datacenter]
}
