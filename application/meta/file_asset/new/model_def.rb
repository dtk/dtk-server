{
  :schema=>:file_asset,
  :table=>:file_asset,
  :columns=>{
    :type => {:type=>:varchar, :size=>25},
    :file_name => {:type=>:varchar, :size=>50},
    :path => {:type=>:varchar},
    :content=> {:type=>:varchar}
  },
  :virtual_columns=>{
    :implementation_info=>{
      :type=>:json,
      :hidden=>true,
      :remote_dependencies=>
      [{
         :model_name=>:implementation,
         :join_type=>:left_outer,
         :join_cond=>{:id=>:file_asset__implementation_implementation_id},
         :cols=>[:id,:display_name,:type,:repo_path]
       }]
    }
  },
  :many_to_one=>[:component,:implementation]
}
