{
  :virtual_columns=>{
    :node_member=> {
      :type=>:json,
      :hidden=>true,
      :remote_dependencies=>
      [{
         :model_name=>:node_group_relation,
         :join_type=>:inner,
         :join_cond=>{:node_group_id=>:node__id},
         :cols=>[:id,:display_name,:node_id]
       },
       {
         :model_name=>:node,
         :alias => :node_member,
         :convert => true,
         :join_type=>:inner,
         :join_cond=>{:id=>:node_group_relation__node_id},
         :cols=>[:id,:display_name,:type]
       }]
    },
  }
}
