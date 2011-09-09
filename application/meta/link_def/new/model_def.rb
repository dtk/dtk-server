{
  :schema=>:link_def,
  :table=>:link_def,
  :columns => {
    :local_or_remote => {:type=>:varchar, :size => 10},
    :link_type => {:type=>:varchar, :size => 50},
    :has_external_link => {:type => :boolean},
    :has_internal_link => {:type => :boolean}
  },
  :many_to_one=>[:component],
  :one_to_many=>[:link_def_link]
}

