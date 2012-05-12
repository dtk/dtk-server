{
  :schema=>:node,
  :table=>:binding_ruleset,
  :columns=>{
    :type => {:type=>:string}, #|| values:: match || clone
    :rules => {:type=>:json}
  },
  :many_to_one=>[:library]
}

