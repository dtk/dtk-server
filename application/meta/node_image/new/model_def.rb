{
  schema: :node,
  table: :image,
  image: {type: :varchar, size: 40},
  properties: {type: :json},
  mappings: {type: :json},
  module_branch_id: {    
    type: :bigint,
    foreign_key_rel_type: :module_branch,
    on_delete: :cascade,
    on_update: :cascade
  },
  many_to_one: [:project]
}
