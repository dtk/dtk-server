{
  schema: :state,
  table: :state_change,
  columns: {
    status: {type: :varchar, default: 'pending', size: 15},
    type: {type: :varchar, size: 25},
    object_type: {type: :varchar, size: 15},
    change: {type: :json},
    change_paths: {type: :json},
    attribute_id: {
      type: :bigint,
      foreign_key_rel_type: :attribute,
      on_delete: :cascade,
      on_update: :cascade
    },
    ancestor_id: {
      type: :bigint,
      foreign_key_rel_type: :state_change,
      on_delete: :set_null,
      on_update: :set_null
    },
    node_id: {
      type: :bigint,
      foreign_key_rel_type: :node,
      on_delete: :cascade,
      on_update: :cascade
    },
    component_id: {
      type: :bigint,
      foreign_key_rel_type: :component,
      on_delete: :cascade,
      on_update: :cascade
    }
  },
  many_to_one: [:datacenter, :state_change],
  one_to_many: [:state_change],
  virtual_columns: {
    changed_component: {
      type: :json,
      hidden: true,
      remote_dependencies:       [{
         model_name: :component,
         convert: true,
         join_type: :inner,
         join_cond: {id: :state_change__component_id},
         cols: [:id,:display_name,:basic_type,:external_ref,:node_node_id,:only_one_per_node,:extended_base_id,:implementation_id]
       },
                                  {
                                    model_name: :node,
                                    convert: true,
                                    join_type: :inner,
                                    join_cond: {id: :component__node_node_id},
                                    cols: [:id, :display_name, :external_ref]
                                  }]
    },
    changed_attribute: {
      type: :json,
      hidden: true,
      remote_dependencies:       [{
         model_name: :attribute,
         join_type: :inner,
         join_cond: {id: :state_change__attribute_id},
         cols: [:id, :component_component_id, :display_name, :value_asserted]
       },
                                  {
                                    model_name: :component,
                                    convert: true,
                                    join_type: :inner,
                                    join_cond: {id: :attribute__component_component_id},
                                    cols: [:id,:display_name,:basic_type,:external_ref,:node_node_id,:only_one_per_node,:extended_base_id]
                                  },
                                  {
                                    model_name: :node,
                                    convert: true,
                                    join_type: :inner,
                                    join_cond: {id: :component__node_node_id},
                                    cols: [:id, :display_name, :external_ref]
                                  }]
    },
    created_node: {
      type: :json,
      hidden: true,
      remote_dependencies:       [{
         model_name: :node,
         convert: true,
         join_type: :inner,
         join_cond: {id: :state_change__node_id},
         cols: [:id,:display_name,:type,:external_ref,:datacenter_datacenter_id,:ancestor_id]
       },
                                  {
                                    model_name: :datacenter,
                                    join_type: :inner,
                                    join_cond: {id: :node__datacenter_datacenter_id},
                                    cols: [:id, :display_name]
                                  }]
    },
    parent_name: {
      possible_parents: [:datacenter, :state_change]
    },
    old_value: {path: [:change, :old]},
    new_value: {path: [:change, :new]}
  }
}
