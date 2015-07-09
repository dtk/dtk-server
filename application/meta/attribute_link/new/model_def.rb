{
  schema: :attribute,
  table: :link,
  columns: {
    input_id: {
      type: :bigint,
      foreign_key_rel_type: :attribute,
      on_delete: :cascade,
      on_update: :cascade
    },
    output_id: {
      type: :bigint,
      foreign_key_rel_type: :attribute,
      on_delete: :cascade,
      on_update: :cascade
    },
    # TODO: may remove :default => "external"; if do, need logic in LinkDefLink#process to pick appropiate type
    type: {type: :varchar, size: 25, default: 'external'}, # "internal" | "external" | "member"
    hidden: {type: :boolean, default: false},
    function: {type: :json, default: 'eq'},
    index_map: {type: :json},
    assembly_id: {
      type: :bigint,
      foreign_key_rel_type: :component,
      on_delete: :set_null,
      on_update: :set_null
    },
    port_link_id: { #optional; used when generated from port link
      type: :bigint,
      foreign_key_rel_type: :port_link,
      on_delete: :cascade,
      on_update: :cascade
    }
  },
  virtual_columns: {
    output_index_map: {
      type: :json,
      hidden: true,
      local_dependencies: [:index_map]
    },
    input_index_map: {
      type: :json,
      hidden: true,
      local_dependencies: [:index_map]
    },
    dangling_link_info: {
      type: :json,
      hidden: true,
      remote_dependencies:       [{
         model_name: :attribute,
         alias: :input_attribute,
         join_type: :inner,
         join_cond: {id: q(:attribute_link,:input_id)},
         cols: [:id,:display_name,:value_derived]
       },
                                  {
                                    model_name: :attribute_link,
                                    alias: :other_input_link,
                                    convert: true,
                                    join_type: :inner,
                                    join_cond: {input_id: q(:attribute_link,:input_id)},
                                    cols: [:id,:type, :input_id,:index_map]
                                  }]
    }
  },
  many_to_one: [:library, :datacenter, :component, :node]
}
