{
  :schema=>:node,
  :table=>:binding_ruleset,
  :columns=>{
    :type => {:type=>:varchar,:size => 10}, #|| values:: match || clone
    :rules => {:type=>:json}
  },
  :many_to_one=>[:library]
}

