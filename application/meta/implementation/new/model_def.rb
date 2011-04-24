{
  :schema=>:implementation,
  :table=>:implementation,
  :columns=>{
    :type => {:type=>:varchar, :size => 25},
    :version => {:type=>:varchar, :size => 25},
    :r8version => {:type=>:varchar, :size => 25, :default => "0.0.1"}
  },
  :many_to_one=>[:library],
  :one_to_many=>[:file_asset]
}
