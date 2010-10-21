#TODO: figure out how to use routing to select/define specific templates
#      and action_set's to be used for a given route

module R8
  Routes = XYZ::HashObject.create_with_auto_vivification()
end

R8::Routes[:login] = {
  :alias => 'user/login',
}
#Routes that correspond to (non-trivial action sets)
R8::Routes["component/display"] = {
  :layout => 'default',
  :alias => '',
  :params => [:id],
  :action_set => 
  [
   {
     :route => "component/display",
     :action_params => ["$id$"],
     :panel => "main_body"
   },
   {
     :route => "attribute/list_for_component_display",
     :action_params => [{:parent_id => "$id$"}],
     :panel => "main_body",
#      :assign_type => 'append | prepend | replace'
     :assign_type => :append 
   },
   {
     :route => "monitoring_item/list_for_component_display",
     :action_params => [{:parent_id => "$id$"}],
     :panel => "main_body",
     :assign_type => :append 
   }
  ]
}

R8::Routes["node/display"] = {
  :layout => 'default',
  :alias => '',
  :params => [:id],
  :action_set => 
  [
   {
     :route => "node/display",
     :action_params => ["$id$"],
     :panel => "main_body"
   },
   {
     :route => "node_interface/list",
     :action_params => [{:parent_id => "$id$"}],
     :panel => "main_body",
     :assign_type => :append 
   },
   {
     :route => "monitoring_item/node_display",
     :action_params => [{:parent_id => "$id$"}],
     :panel => "main_body",
     :assign_type => :append 
   }
  ]
}

R8::Routes["action/list"] = {
  :layout => 'default',
  :alias => '',
  :params => [],
  :action_set => 
  [
   {
     :route => "action/list",
     #:action_id will only pick up top level actions
     :action_params => [{:action_id => nil}],
     :panel => "main_body"
   }
  ]
}

R8::Routes["action/display"] = {
  :layout => 'default',
  :alias => '',
  :params => [:id],
  :action_set => 
  [
   {
     :route => "action/display",
     :action_params => ["$id$"],
     :panel => "main_body"
   },
   {
     :route => "action/list",
     :action_params => [{:parent_id => "$id$"}],
     :panel => "main_body",
     :assign_type => :append 
   }
  ]
}

R8::Routes["component/testjsonlayout"] = {
  :layout => 'testjson'
}

R8::Routes["workspace"] = {
  :layout => 'workspace'
}
R8::Routes["workspace/loaddatacenter"] = {
  :layout => 'workspace'
}

R8::Routes.freeze

