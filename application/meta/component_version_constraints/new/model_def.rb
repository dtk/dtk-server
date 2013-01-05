{
  :schema=>:component,
  :table=>:version_constraints,
  :columns=>{
    #teh contrainst feild is a hash with keys indicating component type and values is constraint on version
    :constraints=>{:type => :json}
  },
  :many_to_one => [:module_branch]
}
