{
  schema: :component,
  table: :include_module,
  columns: {
    version_constraint: {
      type: :json
    }
  },
  many_to_one: [:component]
}
