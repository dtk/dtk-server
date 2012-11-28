{
  :schema=>:node,
  :table=>:binding_ruleset,
  :columns=>{
    :type => {:type=>:varchar,:size => 10}, #|| values:: match || clone
    :os_type => {:type=>:varchar,:size => 15}, 
    :rules => {:type=>:json}
  },
  :many_to_one=>[:library]
}

