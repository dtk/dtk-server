{
  :columns=>{
    :task_template_stage_name => {:type=>:varchar,:size=>50},
    :profile_template_id=>{
      :type=>:bigint,
      :foreign_key_rel_type=>:node,
      :on_delete=>:set_null,
      :on_update=>:set_null
    }
  },
  :virtual_columns=>{
    :node_members=> {
      :type=>:json,
      :hidden=>true,
      :remote_dependencies=>
      [{
         :model_name=>:node_group_relation,
         :join_type=>:inner,
         :convert => true,
         :join_cond=>{:node_group_id=>:node__id},
         :cols=>[:id,:group_id,:display_name,:node_id]
       },
       {
         :model_name=>:node,
         :alias => :node_member,
         :convert => true,
         :join_type => :left_outer,
         :join_cond=>{:id=>:node_group_relation__node_id},
         :cols=>[:id,:group_id,:display_name,:type,:external_ref,:os_type]
       }]
    },
  }
}
