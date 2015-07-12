{
  schema: :node,
  table: :interface,
  columns: {
    type: { type: :varchar, size: 25 },
    ancestor_id: {
      type: :bigint,
      foreign_key_rel_type: :node_interface,
      on_delete: :set_null,
      on_update: :set_null
    },
    address: { type: :json },
    network_partition_id: {
      type: :bigint,
      foreign_key_rel_type: :network_partition,
      on_delete: :cascade,
      on_update: :cascade }
  },
  virtual_columns: {},
  many_to_one: [:node, :node_interface],
  one_to_many: [:node_interface]
}
