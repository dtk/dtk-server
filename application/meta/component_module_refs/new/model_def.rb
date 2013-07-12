lambda__segment_module_branches =
  lambda{|args|
  ret = {
    :model_name=>:module_branch,
    :convert => true,
    :join_type=>:inner,
    :join_cond=>{:id =>:branch_id},
    :cols=>[:id,:display_name,:type,:service_id,:component_id]
  }
  ret
}
lambda__service_for_module_branch =
  lambda{|args|
  ret = {
    :model_name=>:service_module,
    :convert => true,
    :join_type=>:inner,
    :join_cond=>{:id =>:module_branch__service_id},
    :cols=>[:id,:display_name]
  }
  ret
}
{
  :schema=>:module,
  :table=>:version_constraints, #TODO: migrate to global_refs
  :columns=>{
    #the contrainst field is a hash with keys indicating module component and values is constraint on version
    :constraints=>{:type => :json}
  },
  :virtual_columns=>{
    :service_module_info=>{
      :type=>:json,
      :hidden=>true,
      :remote_dependencies=>
      [
      	lambda__segment_module_branches.call(:cols => [:id,:display_name]),
      	lambda__service_for_module_branch.call(:cols => [:id,:display_name])
    	]
    }
  },
  :many_to_one => [:module_branch]
}
