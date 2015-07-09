{
  schema: :dependency,
  table: :component_order,
  columns: {
    after: { type: :varchar, size: 40 }, #this is after component_type specfied here
    conditional: { type: :json }
  },
  many_to_one: [:component]
}
