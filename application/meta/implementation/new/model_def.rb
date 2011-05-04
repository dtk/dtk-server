{
  :schema=>:implementation,
  :table=>:implementation,
  :columns=>{
    :type => {:type=>:varchar, :size => 25},
    :repo_path => {:type=>:varchar, :size => 50},
    :version => {:type=>:varchar, :size => 25},
    :r8version => {:type=>:varchar, :size => 25, :default => "0.0.1"}
  },
  :many_to_one=>[:library,:datacenter],
  :one_to_many=>[:file_asset]
}
