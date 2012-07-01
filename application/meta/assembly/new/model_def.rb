lambda__segment_node =
  lambda{|node_cols|
  {
    :model_name => :node,
    :convert => true,
    :join_type => :inner,
    :join_cond=>{:assembly_id => q(:component,:id)},
    :cols => node_cols
  }
}
lambda__segment_nested_component =
  lambda{|cmp_cols|
  {
    :model_name => :component,
    :convert => true,
    :alias => :nested_component,
    :join_type => :inner,
    :join_cond=>{:node_node_id => q(:node,:id), :assembly_id => q(:component,:id)},
    :cols => cmp_cols
  }
}
lambda__nodes_and_components = 
  lambda{|node_cols,cmp_cols|
  {
    :type => :json, 
    :hidden => true,
    :remote_dependencies =>
    [
     lambda__segment_node.call(node_cols),
     lambda__segment_nested_component.call(cmp_cols)
    ]
  }
}
lambda__template_nodes_and_components = 
  lambda{|node_cols,cmp_ref_cols,cmp_cols|
  {
    :type => :json, 
    :hidden => true,
    :remote_dependencies =>
    [
     lambda__segment_node.call(node_cols),
     {
       :model_name => :component_ref,
       :join_type => :inner,
       :join_cond=>{:node_node_id => q(:node,:id)},
       :cols => cmp_ref_cols
     },
     {
       :model_name => :component,
       :convert => true,
       :alias => :nested_component,
       :join_type => :inner,
       :join_cond=>{:id => q(:component_ref,:component_template_id)},
       :cols => [:id,:display_name,:component_type,:basic_type,:description]
     }]}
}
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
    :nested_nodes_and_cmps=> lambda__nodes_and_components.call(Node.common_columns,Component.common_columns),
    :nested_nodes_and_cmps_summary=> lambda__nodes_and_components.call([:id,:display_name,:external_ref],[:id,:display_name,:component_type,:basic_type,:description]),
    :template_nodes_and_cmps_summary=> lambda__template_nodes_and_components.call([:id,:display_name],[:id,:display_name,:component_template_id],[:id,:display_name,:component_type,:basic_type,:description]),
    :template_link_defs_info=> {
      :type => :json, 
      :hidden => true,
      :remote_dependencies =>
        [
         lambda__segment_node.call([:id,:display_name]),
         {
           :model_name => :component_ref,
           :join_type => :inner,
           :join_cond=>{:node_node_id => q(:node,:id)},
           :cols => [:id,:display_name,:component_template_id]
         },
         {
           :model_name => :component,
           :convert => true,
           :alias => :nested_component,
           :join_type => :inner,
           :join_cond=>{:id => q(:component_ref,:component_template_id)},
           :cols => [:id,:display_name,:component_type, :extended_base, :implementation_id, :node_node_id]
         },
         {
           :model_name => :link_def,
           :convert => true,
           :join_type => :inner,
           :join_cond=>{:component_component_id => q(:nested_component,:id)},
           :cols => [:id,:component_component_id,:local_or_remote,:link_type,:has_external_link,:has_internal_link]
         }]
    },
    :content_instance_nodes_cmps_attrs => {
      :type => :json,
      :hidden => true,
      :remote_dependencies =>
      [
       lambda__segment_node.call(COMMON_REL_COLUMNS.keys + [:node_binding_rs_id]),
       lambda__segment_nested_component.call(COMMON_REL_COLUMNS.keys)
      ]
    },
    :nested_nodes_and_cmps_for_export=> {
      :type => :json, 
      :hidden => true,
      :remote_dependencies =>
        [
         lambda__segment_node.call([:id,:display_name,:external_ref,:node_binding_rs_id]),
         {
           :model_name => :node_binding_ruleset,
           :convert => true,
           :join_type => :inner,
           :join_cond=>{:id => q(:node,:node_binding_rs_id)},
           :cols => [:id,:display_name,:ref]
         },
         lambda__segment_nested_component.call([:id,:display_name,:component_type,:implementation_id]),
         {
           :model_name => :implementation,
           :convert => true,
           :alias => :implementation,
           :join_type => :inner,
           :join_cond=>{:id => q(:nested_component,:implementation_id)},
           :cols => [:id,:display_name,:module_name,:version]
         }]
    },
    :nodes=> {
      :type=>:json,
      :hidden=>true,
      :remote_dependencies=> [lambda__segment_node.call([:id,:display_name,:ui,:type])]
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

