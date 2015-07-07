{
  schema: :task,
  table: :event,
  columns: {
    type: {type: :varchar, size: 20},
    content: {type: :json}
  },
  many_to_one: [:task]
}

