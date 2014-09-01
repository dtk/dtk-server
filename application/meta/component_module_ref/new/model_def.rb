#TODO: this wil be deprecated for module_ref
{
  :schema=>:module,
  :table=>:component_module_ref,
  :columns=>{
    :component_module=>{:type => :varchar, :size => 50},
    :version_info=>{:type => :json},
    :remote_info=>{:type => :json}
  },
  :many_to_one => [:module_branch,:component]
}
