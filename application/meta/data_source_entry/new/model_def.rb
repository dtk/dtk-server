{
  schema: :data_source,
  table: :entry,
  columns: {
    ds_name: { type: :varchar, size: 25 },
    update_policy: { type: :varchar, size: 25 },
    ancestor_id: {
      type: :bigint,
      foreign_key_rel_type: :data_source_entry,
      on_delete: :set_null,
      on_update: :set_null
    },
    source_obj_type: { type: :varchar, size: 25 },
    polling_policy: { type: :json },
    ds_is_golden_store: { type: :boolean, default: true },
    polling_task_id: {
      type: :bigint,
      foreign_key_rel_type: :task,
      on_delete: :set_null,
      on_update: :set_null
    },
    filter: { type: :json },
    placement_location: { type: :json },
    obj_type: { type: :varchar, size: 25 } },
  virtual_columns: {},
  many_to_one: [:data_source, :data_source_entry],
  one_to_many: [:data_source_entry]
}
