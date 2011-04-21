{
  :schema=>:file_asset,
  :table=>:file_asset,
  :columns=>{
    :type => {:type=>:varchar, :size=>25},
    :file_name => {:type=>:varchar, :size=>50},
    :path => {:type=>:varchar},
    :content=> {:type=>:varchar}
  },
  :many_to_one=>[:component,:implementation]
}
