{
  schema: :component,
  table: :assembly_instance_lock,
  columns: {
    module_name: { type: :varchar, size: 30 },
    module_namespace: { type: :varchar, size: 30 },
    service_module_sha: { type: :varchar, size: 50 }
  },
  many_to_one: [:component], #this is an assembly
}
