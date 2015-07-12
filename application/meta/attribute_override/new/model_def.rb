{
  schema: :attribute,
  table: :override,
  columns: {
    attribute_value: { type: :json },
    tags: { type: :json },
    attribute_template_id: {
      type: :bigint,
      foreign_key_rel_type: :attribute,
      on_delete: :cascade,
      on_update: :cascade
    }
  },
  many_to_one: [:component_ref]
}
