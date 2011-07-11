{
  :schema=>:project,
  :table=>:project,
  :columns=>{
    :type => {:type=>:varchar, :size => 25}
  },
  :one_to_many=> [:implementation,:component],
  :virtual_columns=>{
    :targets=>{
      :type=>:json,
      :hidden=>true,
      :remote_dependencies=>
      [{
         :model_name=>:datacenter,
         :alias => :target,
         :convert => true,
         :join_type=>:inner,
         :join_cond=>{:project_id=>:project__id},
         :cols=>[:id,:display_name,:description,:project_id,:iaas_type]
       }]
    },
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
         :convert => true,
         :join_type=>:left_outer,
         :join_cond=>{:datacenter_datacenter_id=>:target__id},
         :cols=>Node.common_columns
       },
       {
         :model_name=>:component,
         :convert => true,
         :join_type=>:left_outer,
         :join_cond=>{:node_node_id=>:node__id},
         :cols=>Component.common_columns
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
         :convert => true,
         :join_type=>:inner,
         :join_cond=>{:node_node_id=>:node__id},
         :cols=>Component.common_columns()
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
