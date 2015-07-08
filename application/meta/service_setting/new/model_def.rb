{
  schema: :service,
  table: :setting,
  columns: {
    node_bindings: {type: :json, ret_keys_as_symbols: false},
    attribute_settings: {type: :json, ret_keys_as_symbols: false}
  },
  virtual_columns: {},
  many_to_one: [:component]
}
