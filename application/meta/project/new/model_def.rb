{
  :schema=>:project,
  :table=>:project,
  :columns=>{
    :type => {:type=>:varchar, :size => 25}
  },
  :virtual_columns=>{
    :tree=>{
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
         :cols=>[:id,:display_name,:description,:node_node_id]
       }]
    }
  }
}
