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
    #like above but wil still return columns if node or ng with no members
    :node_member_include_null=> {
      :type=>:json,
      :hidden=>true,
      :remote_dependencies=>
      [{
         :model_name=>:node_group_relation,
         :join_type=>:left_outer,
         :join_cond=>{:node_group_id=>:node__id},
         :cols=>[:id,:display_name,:node_id]
       },
       {
         :model_name=>:node,
         :alias => :node_member,
         :convert => true,
         :join_type=>:left_outer,
         :join_cond=>{:id=>:node_group_relation__node_id},
         :cols=>[:id,:display_name,:type]
       }]
    }
  }
}
