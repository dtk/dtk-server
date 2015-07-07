# TODO: Marked for removal [Haris]
{
  schema: :link_def,
  table: :attribute_mapping,
  columns: {
    output_attribute_id: {
      type: :bigint,
      foreign_key_rel_type: :attribute,
      on_delete: :cascade,
      on_update: :cascade
    },
    output_component_name: {type: :varchar, size: 50},
    output_attribute_name: {type: :varchar, size: 50},
    output_path: {type: :varchar, size: 50},
    output_contant: {type: :varchar}, #if this is non null that means that input set to a constant value
    input_attribute_id: {
      type: :bigint,
      foreign_key_rel_type: :attribute,
      on_delete: :cascade,
      on_update: :cascade
    },
    input_component_name: {type: :varchar, size: 50},
    input_attribute_name: {type: :varchar, size: 50},
    input_path: {type: :varchar, size: 50},
    function: {type: :varchar, default: "equal"}
  },
  many_to_one: [:link_def_possible_link]
}

