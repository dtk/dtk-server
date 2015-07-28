{
  schema: :action,
  table: :def,
  columns: {
    method_name: { type: :varchar, size: 50 },
    content: { type: :json }
  },
  virtual_columns: {
    parameters: {
      type: :json,
      hidden: true,
      remote_dependencies: 
      [
       { model_name: :attribute,
         alias:      :parameter,  
         convert:    true,
         join_type:  :left_outer,
         join_cond:  { action_def_id: :action_def__id },
         cols:       Attribute.common_columns
       }
      ]
    }
  },
  many_to_one: [:component],
  one_to_many: [:attribute]
}


