{
  schema: :layout,
  table: :layout,
  columns: {
    ancestor_id: {
      type: :bigint,
      foreign_key_rel_type: :layout,
      on_delete: :set_null,
      on_update: :set_null
    },
    type: {
      type: :text,
      length: 20
    },
    is_active: {
      type: :boolean,
      default: true
    },
    def: {
      type: :json
    }
  },
  many_to_one:   [
   # TODO: put in when used  :node,
   :component
  ],
  virtual_columns: {
  }
}
