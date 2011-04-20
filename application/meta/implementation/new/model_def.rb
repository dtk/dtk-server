{
  :schema=>:implementation,
  :table=>:implementation,
  :columns=>{
    :type => {:type=>:varchar, :size => 25}
  },
  :many_to_one=>[:component],
  :one_to_many=>[:file_asset]
}
