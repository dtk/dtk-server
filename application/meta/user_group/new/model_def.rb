{
  schema: :app_user,
  table: :group,
  columns: {
    groupname: {type: :varchar, size: 50}
  },
  one_to_many: [:access_rule]
}
