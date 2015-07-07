{
  schema: :app_user,
  table: :group_relation,
  columns: {
    user_id: {
      type: :bigint,
      foreign_key_rel_type: :user,
      on_delete: :cascade,
      on_update: :cascade
    },
    user_group_id: {
      type: :bigint,
      foreign_key_rel_type: :user_group,
      on_delete: :cascade,
      on_update: :cascade
    }
  }
}
