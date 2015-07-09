{
  schema: :search,
  table: :object,
  columns: { relation: { type: :varchar, size: 25 },
    search_pattern: { type: :json },
    ancestor_id: {
      type: :bigint,
      foreign_key_rel_type: :search_object,
      on_delete: :set_null,
      on_update: :set_null
    }
  }
}
