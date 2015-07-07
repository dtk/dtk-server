{
  schema: :node,
  table: :bindings,
  columns: {
    content: {type: :json}
  },
  many_to_one: [:component]
}

