{
  :schema=>:file_asset,
  :table=>:file_asset,
  :columns=>{
    :path => {:type=>:varchar},
    :content=> {:type=>:varchar}
  },
  :many_to_one=>[:component,:implementation]
}
