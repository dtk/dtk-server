{
  :schema=>:implementation,
  :table=>:implementation,
  :columns=>{
    :type => {:type=>:varchar, :size => 25},
    :version => {:type=>:varchar, :size => 25},
    :r8version => {:type=>:varchar, :size => 25, :default => "0.0.1"}
  },
  :virtual_columns=>{
    :component_info=>{
      :type=>:json,
      :hidden=>true,
      :remote_dependencies=>
      [{
         :model_name=>:component,
         :convert => true,
         :join_type=>:inner,
         :join_cond=>{:implementation_id=>:implementation__id},
         :cols=>[:id,:display_name,:node_node_id]
       },
       {
         :model_name=>:node,
         :join_type=>:inner,
         :join_cond=>{:id=>:component__node_node_id},
         :cols=>[:id,:display_name,:datacenter_datacenter_id]
       }]
    }
  },
  :many_to_one=>[:library,:datacenter],
  :one_to_many=>[:file_asset]
}
