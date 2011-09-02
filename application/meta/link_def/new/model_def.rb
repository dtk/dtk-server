{
  :schema=>:link_def,
  :table=>:link_def,
  :columns => {
    :remote_or_local => {:type=>:varchar, :size => 10},
    :link_type => {:type=>:varchar, :size => 50},
  },
  :many_to_one=>[:component],
  :one_to_many=>[:link_def_possible_link]
}

