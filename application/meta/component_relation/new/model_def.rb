{
  schema: :component,
  table: :relation,
  columns: {
    relation_name: {type: :varchar, size: 50},
    source_component_id: {
      type: :bigint,
      foreign_key_rel_type: :component,
      on_delete: :cascade,
      on_update: :cascade
    },
    target_component_id: {
      type: :bigint,
      foreign_key_rel_type: :component,
      on_delete: :cascade,
      on_update: :cascade
    }
  }, 
  many_to_one: [:library]
}
