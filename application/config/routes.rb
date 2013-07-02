#TODO: figure out how to use routing to select/define specific templates
#      and action_set's to be used for a given route
r8_require('../../utils/internal/routes/routes')

R8::ReactorRoute.draw do

  # USER
  post 'user/process_login'    => "user#process_login"
  get 'user/process_logout'   => "user#process_logout"

   # ASSEMBLY
  post  'assembly/create_new_template' => 'assembly#create_new_template'
  post  'assembly/get_action_results' => 'assembly#get_action_results'
  post  'assembly/find_violations' => 'assembly#find_violations'
  post  'assembly/create_task' => 'assembly#create_task'
  post  'assembly/add__service_add_on' => 'assembly#add__service_add_on'
  post  'assembly/create_smoketests_task' => 'assembly#create_smoketests_task'
  post  'assembly/list_attribute_mappings' => 'assembly#list_attribute_mappings'
  post  'assembly/add_ad_hoc_attribute_mapping' => 'assembly#add_ad_hoc_attribute_mapping'
  post  'assembly/delete_service_link' => 'assembly#delete_service_link'
  post  'assembly/add_ad_hoc_service_link' => 'assembly#add_ad_hoc_service_link'
  post  'assembly/add_connection' => 'assembly#add_connection'
  post  'assembly/list_service_links' => 'assembly#list_service_links'
  post  'assembly/list_remote' => 'assembly#list_remote'
  post  'assembly/list_connections' => 'assembly#list_connections'
  post  'assembly/list_smoketests' => 'assembly#list_smoketests'
  post  'assembly/info' => 'assembly#info'
  post  'assembly/delete' => 'assembly#delete'
  post  'assembly/set_attributes' => 'assembly#set_attributes'
  post  'assembly/get_attributes' => 'assembly#get_attributes'
  post  'assembly/add_assembly_template' => 'assembly#add_assembly_template'
  post  'assembly/add_node' => 'assembly#add_node'
  post  'assembly/add_component' => 'assembly#add_component'
  post  'assembly/initiate_get_log' => 'assembly#initiate_get_log'
  post  'assembly/initiate_grep' => 'assembly#initiate_grep'
  post  'assembly/start' => 'assembly#start'
  post  'assembly/stop' => 'assembly#stop'
  post  'assembly/list' => 'assembly#list'
  post  'assembly/info_about' => 'assembly#info_about'
  post  'assembly/stage' => 'assembly#stage'
  post  'assembly/task_status' => 'assembly#task_status'
  post  'assembly/remove_from_system' => 'assembly#remove_from_system'
  post  'assembly/initiate_get_netstats' => 'assembly#initiate_get_netstats'
  post  'assembly/get_action_results' => 'assembly#get_action_results'
  post  'assembly/delete_component' => 'assembly#delete_component'

   # ATTRIBUTE
  post  'attribute/set' => 'attribute#set'

   # COMPONENT
  post  'component/info' => 'component#info'
  post  'component/list' => 'component#list'
  post  'component/stage' => 'component#stage'

   # COMPONENT_MODULE
  post  'component_module/remove_user_direct_access' => 'component_module#remove_user_direct_access'
  post  'component_module/info_about' => 'component_module#info_about'
  post  'component_module/pull_from_remote' => 'component_module#pull_from_remote'
  post  'component_module/update_model_from_clone' => 'component_module#update_model_from_clone'
  post  'component_module/delete' => 'component_module#delete'
  post  'component_module/test_generate_dsl' => 'component_module#test_generate_dsl'
  post  'component_module/create_new_dsl_version' => 'component_module#create_new_dsl_version'
  post  'component_module/info' => 'component_module#info'
  post  'component_module/list' => 'component_module#list'
  post  'component_module/list_remote' => 'component_module#list_remote'
  post  'component_module/versions' => 'component_module#versions'
  get   'component_module/get_all_workspace_library_diffs' => 'component_module#get_all_workspace_library_diffs'
  post  'component_module/create' => 'component_module#create'
  post  'component_module/import' => 'component_module#import'
  post  'component_module/import_version' => 'component_module#import_version'
  post  'component_module/delete_remote' => 'component_module#delete_remote'
  post  'component_module/export' => 'component_module#export'
  post  'component_module/create_new_version' => 'component_module#create_new_version'
  post  'component_module/get_remote_module_info' => 'component_module#get_remote_module_info'
  post  'component_module/get_workspace_branch_info' => 'component_module#get_workspace_branch_info'
  post  'component_module/update_from_initial_create' => 'component_module#update_from_initial_create'
  post  'component_module/list' => 'component_module#list'
  post  'component_module/add_user_direct_access' => 'component_module#add_user_direct_access'


   # DEPENDENCY
  post  'dependency/add_component_dependency' => 'dependency#add_component_dependency'

   # LIBRARY
  post  'library/list' => 'library#list'
  post  'library/info_about' => 'library#info_about'

   # METADATA
  get 'metadata/get_metadata' => 'metadata#get_metadata'

   # MONITORING_ITEM
  post  'monitoring_item/check_idle' => 'monitoring_item#check_idle'

   # NODE
  post  'node/list' => 'node#list'
  post  'node/info' => 'node#info'
  post  'node/info_about' => 'node#info_about'
  post  'node/get_attributes' => 'node#get_attributes'
  post  'node/set_attributes' => 'node#set_attributes'
  post  'node/add_component' => 'node#add_component'
  post  'node/delete_component' => 'node#delete_component'
  post  'node/create_task' => 'node#create_task'
  post  'node/destroy_and_delete' => 'node#destroy_and_delete'
  post  'node/get_op_status' => 'node#get_op_status'
  post  'node/start' => 'node#start'
  post  'node/stop' => 'node#stop'
  post  'node/task_status' => 'node#task_status'
  post  'node/image_upgrade' => 'node#image_upgrade'
  post  'node/stage' => 'node#stage'
  post  'node/initiate_get_netstats' => 'node#initiate_get_netstats'
  post  'node/get_action_results' => 'node#get_action_results'

   # NODE_GROUP
  post  'node_group/list' => 'node_group#list'
  post  'node_group/get_attributes' => 'node_group#get_attributes '
  post  'node_group/set_attributes' => 'node_group#set_attributes'
  post  'node_group/task_status' => 'node_group#task_status'
  post  'node_group/create' => 'node_group#create'
  post  'node_group/delete' => 'node_group#delete'
  post  'node_group/info_about' => 'node_group#info_about'
  post  'node_group/get_members' => 'node_group#get_members'
  post  'node_group/add_component' => 'node_group#add_component'
  post  'node_group/delete_component' => 'node_group#delete_component'
  post  'node_group/create_task' => 'node_group#create_task'
  post  'node_group/set_default_template_node' => 'node_group#set_default_template_node'
  post  'node_group/clone_and_add_template_node' => 'node_group#clone_and_add_template_node'

   # PROJECT
  post  'project/list' => 'project#list'

   # REPO
  post  'repo/list' => 'repo#list'
  post  'repo/delete' => 'repo#delete'
  post  'repo/synchronize_target_repo' => 'repo#synchronize_target_repo'

   # SERVICE_MODULE
  post  'service_module/list_component_modules' => 'service_module#list_component_modules'
  post  'service_module/remove_user_direct_access' => 'service_module#remove_user_direct_access'
  post  'service_module/update_model_from_clone' => 'service_module#update_model_from_clone'
  post  'service_module/import' => 'service_module#import'
  post  'service_module/create' => 'service_module#create'
  post  'service_module/pull_from_remote' => 'service_module#pull_from_remote'
  post  'service_module/list' => 'service_module#list'
  post  'service_module/list_remote' => 'service_module#list_remote'
  post  'service_module/list_assemblies' => 'service_module#list_assemblies'
  post  'service_module/list_component_modules' => 'service_module#list_component_modules'
  post  'service_module/import_version' => 'service_module#import_version'
  post  'service_module/export' => 'service_module#export'
  post  'service_module/create_new_version' => 'service_module#create_new_version'
  post  'service_module/set_component_module_version' => 'service_module#set_component_module_version'
  post  'service_module/delete' => 'service_module#delete'
  post  'service_module/delete_remote' => 'service_module#delete_remote'
  post  'service_module/get_remote_module_info' => 'service_module#get_remote_module_info'
  post  'service_module/get_workspace_branch_info' => 'service_module#get_workspace_branch_info'
  post  'service_module/add_user_direct_access' => 'service_module#add_user_direct_access'
  # get   'service_module/workspace_branch_info/#{service_module_id.to_s}' => 'service_module#workspace_branch_info/#{service_module_id.to_s}'

   # STATE_CHANGE
  get 'state_change/list_pending_changes' => 'state_change#list_pending_changes'

   # TARGET
  post  'target/list' => 'target#list'
  post  'target/create' => 'target#create'
  post  'target/info_about' => 'target#info_about'
  post  'target/delete' => 'target#delete'
  post  'target/create_assembly_template' => 'target#create_assembly_template'
  
   # TASK
  post  'task/cancel_task' => 'task#cancel_task'
  post  'task/execute' => 'task#execute'
  post  'task/list' => 'task#list'
  post  'task/status' => 'task#status'
  post  'task/create_task_from_pending_changes' => 'task#create_task_from_pending_changes'
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
#  :layout => 'workspace'
  :layout => 'workspace2'
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
#  :layout => 'inventory'
  :layout => 'library'
}
R8::Routes["library/index"] = {
  :layout => 'library'
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
#  :layout => 'ide'
  :layout => 'workspace2'
}
R8::Routes["ide/test_tree"] = {
  :layout => 'ide'
}

R8::Routes["import/index"] = {
  :layout => 'import'
}
R8::Routes["import/load_wizard"] = {
  :layout => 'import'
}
R8::Routes["import/step_one"] = {
  :layout => 'import'
}
R8::Routes["import/step_two"] = {
  :layout => 'import'
}
R8::Routes["import/step_three"] = {
  :layout => 'import'
}

R8::Routes.freeze

