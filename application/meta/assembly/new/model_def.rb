{
  :virtual_columns=>{
    :node_assembly_attributes=> {
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
         :cols=>[:id,:display_name,:component_type]
       },
       {
         :model_name=>:attribute,
         :convert => true,
         :join_type=>:left_outer,
         :join_cond=>{:component_component_id=>:sub_component__id},
         :cols => [:id,:display_name,:hidden,:description,:component_component_id,:attribute_value,:semantic_type,:semantic_type_summary,:data_type,:required,:dynamic,:cannot_change]
       }]
    },
    :nested_nodes_and_cmps=> {
      :type => :json, 
      :hidden => true,
      :remote_dependencies =>
        [
         {
           :model_name => :node,
           :convert => true,
           :join_type => :inner,
           :join_cond=>{:assembly_id => q(:component,:id)},
           :cols => Node.common_columns
         },
         {
           :model_name => :component,
           :convert => true,
           :alias => :nested_component,
           :join_type => :inner,
           :join_cond=>{:node_node_id => q(:node,:id), :assembly_id => q(:component,:id)},
           :cols => Component.common_columns
         }]
    },
    :nested_nodes_and_cmps_summary=> {
      :type => :json, 
      :hidden => true,
      :remote_dependencies =>
        [
         {
           :model_name => :node,
           :convert => true,
           :join_type => :inner,
           :join_cond=>{:assembly_id => q(:component,:id)},
           :cols => [:id,:display_name]
         },
         {
           :model_name => :component,
           :convert => true,
           :alias => :nested_component,
           :join_type => :inner,
           :join_cond=>{:node_node_id => q(:node,:id), :assembly_id => q(:component,:id)},
           :cols => [:id,:display_name,:component_type,:basic_type,:description]
         }]
    },
    :nested_nodes_and_cmps_for_render=> {
      :type => :json, 
      :hidden => true,
      :remote_dependencies =>
        [
         {
           :model_name => :node,
           :convert => true,
           :join_type => :inner,
           :join_cond=>{:assembly_id => q(:component,:id)},
           :cols => [:id,:display_name]
         },
         {
           :model_name => :component,
           :convert => true,
           :alias => :nested_component,
           :join_type => :inner,
           :join_cond=>{:node_node_id => q(:node,:id), :assembly_id => q(:component,:id)},
           :cols => [:id,:display_name,:component_type,:implementation_id]
         },
         {
           :model_name => :implementation,
           :convert => true,
           :alias => :implementation,
           :join_type => :inner,
           :join_cond=>{:id => q(:nested_component,:implementation_id)},
           :cols => [:id,:display_name,:module_name,:version_num]
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

