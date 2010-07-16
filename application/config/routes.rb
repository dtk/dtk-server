
#TODO: figure out how to use routing to select/define specific templates
#      and action_set's to be used for a given route

module R8
  Routes = Hash.new
end
=begin
#alias and action set should not be defined together
#if template not set, should be default at higher level based on user profile
#template should be simple name, higher level will 
#action_set
  If panel_id not set, and panel not explicitly set inside ctrlr action, should default to main_body
routes[:model][:action] = {
  :template => 'tplname',
  :alias => 'some_alternate/route',
  :action_set => {
    {
      :route => 'action1/route',
      :panel_id => 'dom_obj_id',
    }
  },
}
=end

R8::Routes[:workspace] = {
  :template => 'workspace',
}

routes[:node][:list] = {
  :template => '',
  :alias => '',
  :action_set => :some_action_set,
}

routes[:login] = {
  :alias => 'user/login',
}