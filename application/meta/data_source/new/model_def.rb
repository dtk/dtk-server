{
  schema: :data_source,
  table: :data_source,
  columns: {
    ds_name: {type: :varchar, size: 25},
    source_handle: {type: :json},
    ancestor_id: {
      type: :bigint,
      foreign_key_rel_type: :data_source,
      on_delete: :set_null,
      on_update: :set_null
    },
    last_collection_timestamp: {type: :timestamp}},
  virtual_columns: {},
  many_to_one: [:library, :datacenter],
  one_to_many: [:data_source_entry]
}
