{
  schema: :service,
  table: :add_on,
  columns: {
    type: { type: :varchar, size: 50 },
    sub_assembly_id: {
      type: :bigint,
      foreign_key_rel_type: :component,
      on_delete: :cascade,
      on_update: :cascade
    }
  },
  many_to_one: [:component], #this is an assembly
  one_to_many: [:port_link, :service_node_binding]
}
