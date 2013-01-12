lambda__segment_module_branch =
  lambda{|module_branch_cols|
  {
    :model_name=>:module_branch,
    :convert => true,
    :join_type=>:inner,
    :join_cond=>{:id => :component__module_branch_id},
    :cols => module_branch_cols
  }
}
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
segment_component_ref = {
  :model_name => :component_ref,
  :convert => true,
  :join_type => :inner,
  :join_cond=>{:node_node_id => :node__id},
  :cols => [:id,:group_id,:display_name,:component_template_id,:has_override_version,:version,:component_type]
}
lambda__segment_component_template =
  lambda{|join_type|
  {
    :model_name => :component,
    :convert => true,
    :alias => :component_template,
    :join_type => join_type,
    :join_cond=>{:id => q(:component_ref,:component_template_id)},
    :cols => [:id,:display_name,:component_type,:version,:basic_type,:description]
  }
}
lambda__segments_nodes_and_components =
  lambda{|node_cols,cmp_cols|
    [
     {
       :model_name => :component,
       :convert => true,
       :alias => :nested_component,
       :join_type => :inner,
       :join_cond=>{:assembly_id => q(:component,:id)},
       :cols => (cmp_cols + [:node_node_id]).uniq
     },
     {
       :model_name => :node,
       :convert => true,
       :join_type => :inner,
       :join_cond=>{:id => q(:nested_component,:node_node_id)},
       :cols => node_cols
     }]
}
lambda__nodes = 
  lambda{|node_cols|
  {
    :type => :json, 
    :hidden => true,
    :remote_dependencies =>
    [
     lambda__segment_node.call(node_cols)
    ]
  }
}
lambda__instance_nodes_and_components = 
  lambda{|node_cols,cmp_cols|
  {
    :type => :json, 
    :hidden => true,
    :remote_dependencies => lambda__segments_nodes_and_components.call(node_cols,cmp_cols)
  }
}
{
  :virtual_columns=>{
    :target=> {
      :type=>:json,
      :hidden=>true,
      :remote_dependencies=>
      [{
         :model_name=>:datacenter,
         :alias=>:target,
         :convert=>true,
         :join_type=>:inner,
         :join_cond=>{:id=>:component__datacenter_datacenter_id},
         :cols=>[:id,:group_id,:display_name]
       }]
    },
    :module_branch=>{
      :type=>:json,
      :hidden=>true,
      :remote_dependencies=>
      [lambda__segment_module_branch.call([:id,:group_id,:display_name,:branch,:repo_id])]
    },
    :service_module=>{
      :type=>:json,
      :hidden=>true,
      :remote_dependencies=>
      [
       lambda__segment_module_branch.call([:id,:group_id,:display_name,:branch,:repo_id,:service_id]),
       {
         :model_name=>:service_module,
         :convert => true,
         :join_type=>:inner,
         :join_cond=>{:id=>:module_branch__service_id},
         :cols=>[:id,:group_id,:display_name]
       }]
    },
    :node_attributes=> {
      :type=>:json,
      :hidden=>true,
      :remote_dependencies=>
      [{
         :model_name=>:node,
         :join_type=>:inner,
         :join_cond=>{:assembly_id=>:component__id},
         :cols=>[:id,:display_name,:group_id]
       },
       {
         :model_name=>:attribute,
         :convert => true,
         :join_type=>:inner,
         :join_cond=>{:node_node_id=>:node__id},
         :cols => [:id,:display_name,:group_id,:hidden,:description,:component_component_id,:attribute_value,:semantic_type,:semantic_type_summary,:data_type,:required,:dynamic,:cannot_change]
       }]
    },
    :instance_nodes_and_cmps=> lambda__instance_nodes_and_components.call(Node.common_columns,Component.common_columns),
    :instance_nodes_and_cmps_summary=> lambda__instance_nodes_and_components.call([:id,:display_name,:os_type,:external_ref],[:id,:display_name,:component_type,:basic_type,:description]),
    :instance_nested_component_attributes=> {
      :type=>:json,
      :hidden=>true,
      :remote_dependencies=>
        lambda__segments_nodes_and_components.call([:id,:display_name,:group_id],[:id,:display_name,:component_type,:group_id]) +
      [{
        :model_name=>:attribute,
        :convert => true,
        :join_type=>:inner,
        :join_cond=>{:component_component_id=>:nested_component__id},
        :cols => [:id,:display_name,:group_id,:hidden,:description,:component_component_id,:attribute_value,:semantic_type,:semantic_type_summary,:data_type,:required,:dynamic,:cannot_change,:port_type_asserted, :is_port]
      }]
    },

    :nested_nodes_summary=> lambda__nodes.call([:id,:display_name,:type,:os_type,:admin_op_status,:external_ref]),
    :augmented_component_refs=>{
      :type => :json, 
      :hidden => true,
      :remote_dependencies =>
      [
       lambda__segment_node.call([:id,:group_id,:display_name,:os_type]),
       segment_component_ref,
       lambda__segment_component_template.call(:left_outer),
       {
         :model_name => :module_version_constraints,
         :convert => true,
         :join_type => :left_outer,
         :join_cond=>{:branch_id => q(:component,:module_branch_id)},
         :cols => [:id,:display_name,:group_id,:constraints,:service_id,:component_id]
       }
      ]
    },
    #MOD_RESTRUCT: deprecate below for above
    :template_nodes_and_cmps_summary=> {
      :type => :json, 
      :hidden => true,
      :remote_dependencies =>
      [
       lambda__segment_node.call([:id,:display_name,:os_type]),
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
         :cols => [:id,:display_name,:component_type,:basic_type,:description]
       }]
    },
    :template_link_defs_info=> {
      :type => :json, 
      :hidden => true,
      :remote_dependencies =>
        [
         lambda__segment_node.call([:id,:display_name]),
         segment_component_ref,
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
    #MOD_RESTRUCT: this must be removed or changed to reflect more advanced relationship between component ref and template
    :component_templates=> { 
      :type => :json, 
      :hidden => true,
      :remote_dependencies =>
        [
         lambda__segment_node.call([:id,:display_name]),
         segment_component_ref,
         {
           :model_name => :component,
           :convert => true,
           :alias => :component_template,
           :join_type => :inner,
           :join_cond=>{:id => q(:component_ref,:component_template_id)},
           :cols => [:id,:display_name,:group_id,:component_type,:version,:module_branch_id]
         }]
    },
    :tasks=> {
      :type=>:json,
      :hidden=>true,
      :remote_dependencies=> 
      [{
         :model_name => :task,
         :convert => true,
         :join_type => :inner,
         :join_cond=>{:assembly_id => q(:component,:id)},
         :cols => [:id,:display_name,:status,:created_at,:started_at,:ended_at,:commit_message]
       }]
    },
    :node_templates=> {
      :type=>:json,
      :hidden=>true,
      :remote_dependencies=> 
      [lambda__segment_node.call([:id,:display_name,:os_type,:node_binding_rs_id]),
       {
         :model_name => :node_binding_ruleset,
         :convert => true,
         :alias => :node_binding,
         :join_type => :inner,
         :join_cond=>{:id => q(:node,:node_binding_rs_id)},
         :cols => [:id,:display_name,:os_type,:rules]
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
    },
    :service_add_ons_from_instance=> {
      :type=>:json,
      :hidden=>true,
      :remote_dependencies=>
      [{
         :model_name=>:component,
         :alias => :template,
         :join_type=>:inner,
         :join_cond=>{:id=>:component__ancestor_id},
         :cols=>[:id,:display_name]
       },
       {
         :model_name=>:service_add_on,
         :convert => true,
         :join_type=>:inner,
         :join_cond=>{:component_component_id=>:template__id},
         :cols=>[:id,:display_name,:type,:description]
       }],
    },
    :aug_service_add_ons_from_instance=> {
      :type=>:json,
      :hidden=>true,
      :remote_dependencies=>
      [{
         :model_name=>:component,
         :alias => :template,
         :join_type=>:inner,
         :join_cond=>{:id=>:component__ancestor_id},
         :cols=>[:id,:group_id,:display_name]
       },
       {
         :model_name=>:service_add_on,
         :convert => true,
         :join_type=>:inner,
         :join_cond=>{:component_component_id=>:template__id},
         :cols=>[:id,:group_id,:display_name,:type,:sub_assembly_id]
       },
       {
         :model_name=>:component,
         :convert => true,
         :alias => :sub_assembly_template,
         :join_type=>:inner,
         :join_cond=>{:id=>:service_add_on__sub_assembly_id},
         :cols=>[:id,:group_id,:display_name]
       }]
    }
  }
}
