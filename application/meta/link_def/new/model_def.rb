{
  :schema=>:link_def,
  :table=>:link_def,
  :columns => {
    :local_or_remote => {:type=>:varchar, :size => 10},
    :link_type => {:type=>:varchar, :size => 50},
    :required => {:type=>:boolean},
    :dangling => {:type=>:boolean, :default=>false},
    :has_external_link => {:type => :boolean},
    :has_internal_link => {:type => :boolean}
  },
  :many_to_one=>[:component],
  :one_to_many=>[:link_def_link]
}

