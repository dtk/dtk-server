{
  schema: :task,
  table: :template,
  columns: {
    content: { type: :json },
    task_action: { type: :varchar, size: 30 }
  },
  many_to_one: [:component]
}
