{
  :schema=>:file_asset,
  :table=>:file_asset,
  :columns=>{
    :file_name => {:type=>:varchar, :size=>50},
    :path => {:type=>:varchar},
    :content=> {:type=>:varchar}
  },
  :many_to_one=>[:component,:implementation]
}
