{
  :schema=>:implementation,
  :table=>:implementation,
  :columns=>{
    :type => {:type=>:varchar, :size => 25},
    :repo => {:type=>:varchar, :size => 25}, #TODO: not normalized not that repo_id added; may deprecate
    :module_name => {:type=>:varchar, :size => 25}, 
    :branch => {:type=>:varchar, :size => 50, :default => "master"},
    :version_num => {:type=>:integer, :default => 1},
    :updated => {:type=>:boolean, :default => false}
  },
  :repo_id=>{
    :type=>:bigint,
    :foreign_key_rel_type=>:attribute,
    :on_delete=>:set_null,
    :on_update=>:set_null
  },
  :virtual_columns=>{
    :component_summary_info=>{
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
         :filter => [:neq,:datacenter_datacenter_id,nil],
         :cols=>[:id,:display_name,:datacenter_datacenter_id]
       }]
    },
    #getting just templates with this implementation
    :component_template =>{
      :type=>:json,
      :hidden=>true,
      :remote_dependencies=>
      [{
         :model_name=>:component,
         :convert => true,
         :join_type=>:inner,
         :filter => [:eq, :node_node_id, nil],
         :join_cond=>{:implementation_id=>:implementation__id},
         :cols=>Component.common_columns
       }]
    },
    :linked_library_implementation=>{
      :type=>:json,
      :hidden=>true,
      :remote_dependencies=>
      [{
         :model_name=>:implementation,
         :alias => :library_implementation,
         :convert => true,
         :join_type=>:inner,
         :join_cond=>{:id=>:implementation__ancestor_id},
         :cols=>[:id,:repo,:branch]
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
