{
  :schema=>:project,
  :table=>:project,
  :columns=>{
    :type => {:type=>:varchar, :size => 25}
  },
  :one_to_many=> [:implementation],
  :virtual_columns=>{
    :target_tree=>{
      :type=>:json,
      :hidden=>true,
      :remote_dependencies=>
      [{
         :model_name=>:datacenter,
         :alias => :target,
         :join_type=>:inner,
         :join_cond=>{:project_id=>:project__id},
         :cols=>[:id,:display_name,:description,:project_id,:iaas_type]
       },
       {
         :model_name=>:node,
         :join_type=>:left_outer,
         :join_cond=>{:datacenter_datacenter_id=>:target__id},
         :cols=>[:id,:display_name,:description,:datacenter_datacenter_id,:os_type]
       },
       {
         :model_name=>:component,
         :convert => true,
         :join_type=>:left_outer,
         :join_cond=>{:node_node_id=>:node__id},
         :cols=>[:id,:display_name,:description,:node_node_id,:basic_type,:specific_type,:component_type]
       }]
    },
    :implementation_tree=>{
      :type=>:json,
      :hidden=>true,
      :remote_dependencies=>
      [{
         :model_name=>:datacenter,
         :alias => :target,
         :join_type=>:inner,
         :join_cond=>{:project_id=>:project__id},
         :cols=>[:id,:display_name,:description,:project_id,:iaas_type]
       },
       {
         :model_name=>:node,
         :join_type=>:inner,
         :join_cond=>{:datacenter_datacenter_id=>:target__id},
         :cols=>[:id,:display_name,:datacenter_datacenter_id]
       },
       {
         :model_name=>:component,
         :join_type=>:inner,
         :join_cond=>{:node_node_id=>:node__id},
         :cols=>[:id,:display_name,:node_node_id,:ancestor_id,:implementation_id]
       },
       {
         :model_name=>:component,
         :alias => :component_template,
         :convert => true,
         :join_type=>:inner,
         :join_cond=>{:id=>:component__ancestor_id},
         :cols=>[:id,:display_name,:description,:ancestor_id,:basic_type,:specific_type,:component_type]
       },
       {
         :model_name=>:implementation,
         :convert => true,
         :join_type=>:inner,
         :join_cond=>{:id=>:component__implementation_id},
         :cols=>[:id,:display_name,:type]
       }]
    }
  }
}
