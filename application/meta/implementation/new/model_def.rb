{
  :schema=>:implementation,
  :table=>:implementation,
  :columns=>{
    :type => {:type=>:varchar, :size => 25},
    :repo => {:type=>:varchar, :size => 25},
    :version_num => {:type=>:integer, :default => 1},
    :updated => {:type=>:boolean, :default => false}
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
    },
    :file_assets=>{
      :type=>:json,
      :hidden=>true,
      :remote_dependencies=>
      [{
         :model_name=>:file_asset,
         :convert => true,
         :join_type=>:inner,
         :join_cond=>{:implementation_implementation_id => :implementation__id},
         :cols=>[:id,:file_name,:type,:path]
       }]
    }
  },
  :many_to_one=>[:library,:project],
  :one_to_many=>[:file_asset]
}
