#TODO: figure out how to use routing to select/define specific templates
#      and action_set's to be used for a given route

module R8
  Routes = XYZ::HashObject.create_with_auto_vivification()
end

R8::Routes[:login] = {
  :alias => 'user/login',
}
#Routes that correspond to (non-trivial action sets)
=begin
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
=end
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

R8::Routes["state_change/list_pending"] = {
  :layout => 'default',
  :alias => '',
  :params => [],
  :action_set => 
  [
   {
     :route => "state_change/list",
     #:state_change_id => nil will only pick up top level state changes second condition just picks out pending changes
     :action_params => [{:state_change_id => nil}, {:status => "pending"}],
     :panel => "main_body"
   }
  ]
}

R8::Routes["state_change/display"] = {
  :layout => 'default',
  :alias => '',
  :params => [:id],
  :action_set => 
  [
   {
     :route => "state_change/display",
     :action_params => ["$id$"],
     :panel => "main_body"
   },
   {
     :route => "state_change/list",
     :action_params => [{:parent_id => "$id$"}],
     :panel => "main_body",
     :assign_type => :append 
   }
  ]
}

R8::Routes["task/list"] = {
  :layout => 'default',
  :alias => '',
  :params => [],
  :action_set => 
  [
   {
     :route => "task/list",
     #:task_id will only pick up top level tasks
     :action_params => [{:task_id => nil}],
     :panel => "main_body"
   }
  ]
}

R8::Routes["task/display"] = {
  :layout => 'default',
  :alias => '',
  :params => [:id],
  :action_set => 
  [
   {
     :route => "task/display",
     :action_params => ["$id$"],
     :panel => "main_body"
   },
   {
     :route => "task/list",
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
R8::Routes["workspace/index"] = {
  :layout => 'workspace'
}
R8::Routes["workspace/loaddatacenter"] = {
  :layout => 'workspace'
}
R8::Routes["workspace/list_items"] = {
  :layout => 'workspace'
}
R8::Routes["workspace/list_items_new"] = {
  :layout => 'workspace'
}

R8::Routes["workspace/list_items_2"] = {
  :layout => 'workspace'
}

R8::Routes["user/login"] = {
  :layout => 'login'
}

R8::Routes["user/register"] = {
  :layout => 'login'
}

R8::Routes["datacenter/load_vspace"] = {
  :layout => 'workspace'
}


R8::Routes["component/details"] = {
  :layout => 'details2'
}
R8::Routes["component/details2"] = {
  :layout => 'details2'
}

R8::Routes["datacenter/list"] = {
  :layout => 'dashboard'
}
R8::Routes["component/list"] = {
  :layout => 'inventory'
}

R8::Routes["node/list"] = {
  :layout => 'inventory'
}

R8::Routes["datacenter/list"] = {
  :layout => 'inventory'
}

R8::Routes["inventory/index"] = {
  :layout => 'inventory'
}

R8::Routes["editor/index"] = {
  :layout => 'editor'
}

R8::Routes["ide/index"] = {
  :layout => 'ide'
}
R8::Routes["ide/test_tree"] = {
  :layout => 'ide'
}

R8::Routes.freeze

