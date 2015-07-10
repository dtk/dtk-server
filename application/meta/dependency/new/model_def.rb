{
  schema: :dependency,
  table: :dependency,
  columns: {
    type: { type: :varchar, size: 20 },
    search_pattern: { type: :json },
    severity: { type: :varchar, size: 20 } # error || warning || ..
  },
  many_to_one: [:component, :attribute]
}
