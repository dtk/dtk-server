{
  :schema=>:link_def,
  :table=>:link_def,
  :type => {:type=>:varchar, :size => 50},
  :many_to_one=>[:component],
  :one_to_many=>[:link_def_possible_link]
}

