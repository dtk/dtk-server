{
  schema: :task,
  table: :error,
  columns: {
    message: {type: :varchar},
    content: {type: :json},
    component_id: {
      type: :bigint,
      foreign_key_rel_type: :component,
      on_delete: :cascade,
      on_update: :cascade
    }
  },
  many_to_one: [:task]
}
