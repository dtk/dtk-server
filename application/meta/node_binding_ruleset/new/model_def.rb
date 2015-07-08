{
  schema: :node,
  table: :binding_ruleset,
  columns: {
    type: {type: :varchar,size: 10}, #|| values:: match || clone
    os_type: {type: :varchar,size: 25},
    os_identifier: {type: :varchar, size: 50}, #augments os_type to identify specifics about os. From os_identier given region one can find unique ami
    rules: {type: :json}
  },
  many_to_one: [:library]
}
