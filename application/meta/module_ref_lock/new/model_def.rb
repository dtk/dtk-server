{
  schema: :module,
  table: :module_ref_lock,
  columns: {
    module_name: {type: :varchar,size: 30},
    info: {type: :json},
    locked_branch_sha: {type: :varchar,size: 50},
  },
  many_to_one: [:component], #this is an assembly
}
