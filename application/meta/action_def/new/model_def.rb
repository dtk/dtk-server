{
  schema: :action,
  table: :def,
  columns: {
    method_name: {type: :varchar, size: 50},
    content: {type: :json}
  },
  many_to_one: [:component]
}
