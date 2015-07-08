{
  columns: {
    # TODO: think these may not be used;
    task_template_stage_name: {type: :varchar,size: 50},
    profile_template_id: {
      type: :bigint,
      foreign_key_rel_type: :node,
      on_delete: :set_null,
      on_update: :set_null
    }
  },
  virtual_columns: {
    node_members: {
      type: :json,
      hidden: true,
      remote_dependencies:       [{
         model_name: :node_group_relation,
         join_type: :inner,
         convert: true,
         join_cond: {node_group_id: :node__id},
         cols: [:id,:group_id,:display_name,:node_id,:datacenter_datacenter_id]
       },
                                  {
                                    model_name: :node,
                                    alias: :node_member,
                                    convert: true,
                                    join_type: :left_outer,
                                    join_cond: {id: :node_group_relation__node_id},
                                    cols: Node.common_columns()
                                  },
                                  {
                                    model_name: :datacenter,
                                    alias: :target,
                                    convert: true,
                                    join_type: :inner,
                                    join_cond: {id: :node_group_relation__datacenter_datacenter_id},
                                    cols: [:id,:group_id,:display_name,:iaas_properties]
                                  }]
    },
  }
}
