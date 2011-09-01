{
  :schema=>:link_def,
  :table=>:posible_link,
  :columns=>{
    :remote_component_type => {:type=>:varchar, :size => 50},
    :position => {:type =>:integer},
    :content => {:type => :json}, 
    :type => {:type=>:varchar, :size => 10}, #internal || external || either
  },
  :many_to_one=>[:link_def]
}

