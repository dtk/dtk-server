{
  schema: :link_def,
  table: :link,
  columns: {
    remote_component_type: {type: :varchar, size: 50},
    position: {type: :integer},
    content: {type: :json},
    temporal_order: {type: :varchar, size: 10}, #before || after #before means that dependendent before base component
    type: {type: :varchar, size: 10}, #internal || external || internal_external
  },
  many_to_one: [:link_def]
}
