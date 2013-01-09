{
  :schema=>:module,
  :table=>:version_constraints,
  :columns=>{
    #the contrainst field is a hash with keys indicating module component and values is constraint on version
    :constraints=>{:type => :json}
  },
  :many_to_one => [:module_branch]
}
