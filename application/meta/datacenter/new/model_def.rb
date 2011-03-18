{
  :schema=>:datacenter,
  :table=>:datacenter,
  :columns=>{
    :ancestor_id=> {
      :type=>:bigint,
      :foreign_key_rel_type=>:datacenter,
      :on_delete=>:set_null,
      :on_update=>:set_null
    },
    :ui=> {
      :type=>:json
    }
  },
  :one_to_many=>
  [
   :data_source,
   :node,
   :state_change,
   :node_group,
   :node_group_member,
   :attribute_link,
   :port_link,
   :network_partition,
   :network_gateway,
   :component,
   :violation
  ],
  :virtual_columns=>{
    :nodes=>{
      :type=>:json,
      :hidden=>true,
      :remote_dependencies=>
      [{
         :model_name=>:node,
         :convert => true,
         :join_type=>:inner,
         :join_cond=>{:datacenter_datacenter_id=>:datacenter__id},
         :cols=>[:id,:display_name,:ui,:type]
       }]
    },
    :node_groups=>{
      :type=>:json,
      :hidden=>true,
      :remote_dependencies=>
      [{
         :model_name=>:node_group,
         :convert => true,
         :join_type=>:inner,
         :join_cond=>{:datacenter_datacenter_id=>:datacenter__id},
         :cols=>[:id,:display_name,:ui,:type]
       }]
    },
    :violations=>{
      :type=>:json,
      :hidden=>true,
      :remote_dependencies=>
      [{
         :model_name=>:violation,
         :convert => true,
         :join_type=>:inner,
         :join_cond=>{:datacenter_datacenter_id=>:datacenter__id},
         :cols=>[:id,:display_name,:severity,:description,:expression,:target_node_id,:updated_at]
       }]
    }
  }
}
