
#TODO: figure out how to use routing to select/define specific templates
#      and action_set's to be used for a given route

module R8
  Routes = Hash.new
end

R8::Routes[:workspace] = {
  :template => 'workspace.template.erubis',
  :action_set => 'nothing yet'
}
