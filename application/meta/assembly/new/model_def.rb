{
  :virtual_columns=>{
    :assembly_unravel_attributes=> {
      :type=>:json,
      :hidden=>true,
      :remote_dependencies=>
      [{
         :model_name=>:node,
         :join_type=>:inner,
         :join_cond=>{:assembly_id=>:component__id},
         :cols=>[:id,:display_name]
       },
       {
         :model_name=>:component,
         :alias=>:sub_component,
         :join_type=>:inner,
         :join_cond=>{:node_node_id=>:node__id},
         :cols=>[:id,:display_name]
       },
       {
         :model_name=>:attribute,
         :join_type=>:left_outer,
         :filter => [:and,[:eq, :hidden, false]],
         :join_cond=>{:component_component_id=>:sub_component__id},
         :cols=>[:id,:display_name,:attribute_value,:semantic_type,:semantic_type_summary,:data_type,:required,:dynamic,:cannot_change]
       }]
    },
    :nodes=> {
      :type=>:json,
      :hidden=>true,
      :remote_dependencies=>
      [{
         :model_name=>:node,
         :convert => true,
         :join_type=>:inner,
         :join_cond=>{:assembly_id=>:component__id},
         :cols=>[:id,:display_name,:ui,:type]
       }]
    },
    :components=> {
      :type=>:json,
      :hidden=>true,
      :remote_dependencies=>
      [{
         :model_name=>:component,
         :convert => true,
         :join_type=>:inner,
         :join_cond=>{:assembly_id=>:component__id},
         :cols=>[:id,:display_name,:ui,:type]
       }]
    }
  }
}

