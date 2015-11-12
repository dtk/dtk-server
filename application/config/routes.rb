# TODO: figure out how to use routing to select/define specific templates
#      and action_set's to be used for a given route
r8_require('../../utils/internal/routes/routes')

R8::ReactorRoute.draw do
  # V1 Namespace
  get  'api/v1/service/:service_id'               => 'v1::service#info'
  get  'api/v1/service/:service_id/nodes'         => 'v1::service#nodes'
  get  'api/v1/service/:service_id/components'    => 'v1::service#components'
  get  'api/v1/service/:service_id/tasks'         => 'v1::service#tasks'
  get  'api/v1/service/:service_id/access_tokens' => 'v1::service#access_tokens'

  post 'api/v1/service/:service_id/converge'        => 'v1::service#converge'
  post 'api/v1/service/:service_id/start'           => 'v1::service#start'
  post 'api/v1/service/:service_id/stop'            => 'v1::service#stop'
  post 'api/v1/service/:service_id/create_assembly' => 'v1::service#create_assembly'

  delete 'api/v1/service/:service_id' => 'v1::service#delete_destroy'

  # USER
  post 'user/process_login'      => 'user#process_login'
  get 'user/process_logout'     => 'user#process_logout'

  # MESSAGES
  get 'messages/retrieve'       => 'messages#retrieve'

  # INTEGRATION
  post 'integration/spin_tenant' => 'integration#spin_tenant'

  # DEVELOPER
  post 'developer/run_agent' => 'developer#run_agent'

  # ACCOUNT
  post 'account/set_password' => 'account#set_password'
  post 'account/list_ssh_keys' => 'account#list_ssh_keys'
  post 'account/add_user_direct_access' => 'account#add_user_direct_access'
  post 'account/remove_user_direct_access' => 'account#remove_user_direct_access'
  post 'account/set_default_namespace' => 'account#set_default_namespace'
  post 'account/set_catalog_credentials' => 'account#set_catalog_credentials'
  post 'account/check_catalog_credentials' => 'account#check_catalog_credentials'

  # ASSEMBLY
  post 'assembly/promote_to_template' => 'assembly#promote_to_template'
  post 'assembly/get_action_results' => 'assembly#get_action_results'
  post 'assembly/find_violations' => 'assembly#find_violations'
  post 'assembly/create_task' => 'assembly#create_task'
  post 'assembly/ad_hoc_action_list' => 'assembly#ad_hoc_action_list'
  post 'assembly/ad_hoc_action_execute' => 'assembly#ad_hoc_action_execute'

  post 'assembly/create_smoketests_task' => 'assembly#create_smoketests_task'
  post 'assembly/add_ad_hoc_attribute_links' => 'assembly#add_ad_hoc_attribute_links'
  post 'assembly/delete_service_link' => 'assembly#delete_service_link'
  post 'assembly/add_service_link' => 'assembly#add_service_link'
  post 'assembly/list_service_links' => 'assembly#list_service_links'
  post 'assembly/list_remote' => 'assembly#list_remote'
  post 'assembly/list_connections' => 'assembly#list_connections'
  post 'assembly/task_action_list' => 'assembly#task_action_list'
  post 'assembly/list_with_workspace' => 'assembly#list_with_workspace'
  post 'assembly/info' => 'assembly#info'
  post 'assembly/delete' => 'assembly#delete'
  post 'assembly/destroy_and_reset_nodes' => 'assembly#destroy_and_reset_nodes'
  post 'assembly/purge' => 'assembly#purge' #workspace command
  post 'assembly/set_target' => 'assembly#set_target' #workspace command
  post 'assembly/set_attributes' => 'assembly#set_attributes'
  post 'assembly/apply_attribute_settings' => 'assembly#apply_attribute_settings'
  post 'assembly/get_attributes' => 'assembly#get_attributes'
  post 'assembly/add_assembly_template' => 'assembly#add_assembly_template'
  post 'assembly/add_node' => 'assembly#add_node'
  post 'assembly/add_component' => 'assembly#add_component'
  post 'assembly/initiate_get_log' => 'assembly#initiate_get_log'
  post 'assembly/initiate_grep' => 'assembly#initiate_grep'
  post 'assembly/initiate_get_ps' => 'assembly#initiate_get_ps'
  post 'assembly/initiate_execute_tests' => 'assembly#initiate_execute_tests'
  post 'assembly/list_component_module_diffs' => 'assembly#list_component_module_diffs'
  post 'assembly/print_includes' => 'assembly#print_includes'
  post 'assembly/task_action_detail' => 'assembly#task_action_detail'
  post 'assembly/add_node_group' => 'assembly#add_node_group'
  post 'assembly/prepare_for_pull_from_base' => 'assembly#prepare_for_pull_from_base'

  post 'assembly/start' => 'assembly#start'
  post 'assembly/stop' => 'assembly#stop'
  post 'assembly/list' => 'assembly#list'
  post 'assembly/info_about' => 'assembly#info_about'
  post 'assembly/info_about_task' => 'assembly#info_about_task'
  post 'assembly/stage' => 'assembly#stage'
  post 'assembly/deploy' => 'assembly#deploy'
  post 'assembly/task_status' => 'assembly#task_status'
  post 'assembly/remove_from_system' => 'assembly#remove_from_system'
  post 'assembly/initiate_get_netstats' => 'assembly#initiate_get_netstats'
  post 'assembly/get_action_results' => 'assembly#get_action_results'
  post 'assembly/delete_node' => 'assembly#delete_node'
  post 'assembly/delete_component' => 'assembly#delete_component'
  post 'assembly/prepare_for_edit_module' => 'assembly#prepare_for_edit_module'
  post 'assembly/promote_module_updates' => 'assembly#promote_module_updates'
  post 'assembly/clear_tasks' => 'assembly#clear_tasks'
  post 'assembly/cancel_task' => 'assembly#cancel_task'
  post 'assembly/initiate_ssh_pub_access' => 'assembly#initiate_ssh_pub_access'
  post 'assembly/list_ssh_access' => 'assembly#list_ssh_access'
  post 'assembly/list_settings' => 'assembly#list_settings'
  post 'assembly/get_component_modules' => 'assembly#get_component_modules'
  post 'assembly/delete_node_group' => 'assembly#delete_node_group'
  post 'assembly/get_node_groups' => 'assembly#get_node_groups'
  post 'assembly/get_nodes_without_node_groups' => 'assembly#get_nodes_without_node_groups'
  post 'assembly/task_action_list' => 'assembly#task_action_list'

  # ATTRIBUTE
  post 'attribute/set' => 'attribute#set'

  # COMPONENT
  post 'component/info' => 'component#info'
  post 'component/list' => 'component#list'
  post 'component/stage' => 'component#stage'

  # COMPONENT_MODULE
  post 'component_module/add_user_direct_access' => 'account#add_user_direct_access'
  post 'component_module/info_about' => 'component_module#info_about'
  post 'component_module/pull_from_remote' => 'component_module#pull_from_remote'
  post 'component_module/update_model_from_clone' => 'component_module#update_model_from_clone'
  post 'component_module/delete' => 'component_module#delete'
  post 'component_module/delete_version' => 'component_module#delete_version'
  post 'component_module/info' => 'component_module#info'
  post 'component_module/list' => 'component_module#list'
  post 'component_module/pull_from_remote' => 'component_module#pull_from_remote'
  post 'component_module/remote_chmod' => 'component_module#remote_chmod'
  post 'component_module/remote_chown' => 'component_module#remote_chown'
  post 'component_module/confirm_make_public' => 'component_module#confirm_make_public'
  post 'component_module/remote_collaboration' => 'component_module#remote_collaboration'
  post 'component_module/list_remote_collaboration' => 'component_module#list_remote_collaboration'
  post 'component_module/resolve_pull_from_remote' => 'component_module#resolve_pull_from_remote'
  post 'component_module/list_remote' => 'component_module#list_remote'
  post 'component_module/versions' => 'component_module#versions'
  post 'component_module/create' => 'component_module#create'
  post 'component_module/import' => 'component_module#import'
  post 'component_module/import_version' => 'component_module#import_version'
  post 'component_module/delete_remote' => 'component_module#delete_remote'
  post 'component_module/export' => 'component_module#export'
  post 'component_module/get_remote_module_info' => 'component_module#get_remote_module_info'
  post 'component_module/get_workspace_branch_info' => 'component_module#get_workspace_branch_info'
  post 'component_module/update_from_initial_create' => 'component_module#update_from_initial_create'
  post 'component_module/list' => 'component_module#list'
  post 'component_module/install_puppet_forge_modules' => 'component_module#install_puppet_forge_modules'
  post 'component_module/list_remote_diffs' => 'component_module#list_remote_diffs'
  post 'component_module/create_new_version' => 'component_module#create_new_version'
  post 'component_module/list_versions' => 'component_module#list_versions'
  post 'component_module/check_remote_exist' => 'component_module#check_remote_exist'

  # WORK WITH GIT REMOTES
  post 'component_module/info_git_remote'        => 'component_module#info_git_remote'
  post 'component_module/add_git_remote'         => 'component_module#add_git_remote'
  post 'component_module/remove_git_remote'      => 'component_module#remove_git_remote'

  # TEST_MODULE
  post 'test_module/add_user_direct_access' => 'account#add_user_direct_access'
  post 'test_module/info_about' => 'test_module#info_about'
  post 'test_module/pull_from_remote' => 'test_module#pull_from_remote'
  post 'test_module/update_model_from_clone' => 'test_module#update_model_from_clone'
  post 'test_module/delete' => 'test_module#delete'
  post 'test_module/delete_version' => 'test_module#delete_version'
  post 'test_module/info' => 'test_module#info'
  post 'test_module/list' => 'test_module#list'
  post 'test_module/pull_from_remote' => 'test_module#pull_from_remote'
  post 'test_module/remote_chmod' => 'test_module#remote_chmod'
  post 'test_module/remote_chown' => 'test_module#remote_chown'
  post 'test_module/confirm_make_public' => 'test_module#confirm_make_public'
  post 'test_module/remote_collaboration' => 'test_module#remote_collaboration'
  post 'test_module/list_remote_collaboration' => 'test_module#list_remote_collaboration'
  post 'test_module/resolve_pull_from_remote'  => 'test_module#resolve_pull_from_remote'
  post 'test_module/list_remote' => 'test_module#list_remote'
  post 'test_module/versions' => 'test_module#versions'
  post 'test_module/create' => 'test_module#create'
  post 'test_module/import' => 'test_module#import'
  post 'test_module/import_version' => 'test_module#import_version'
  post 'test_module/delete_remote' => 'test_module#delete_remote'
  post 'test_module/export' => 'test_module#export'
  post 'test_module/get_remote_module_info' => 'test_module#get_remote_module_info'
  post 'test_module/get_workspace_branch_info' => 'test_module#get_workspace_branch_info'
  post 'test_module/update_from_initial_create' => 'test_module#update_from_initial_create'
  post 'test_module/list' => 'test_module#list'
  post 'test_module/list_remote_diffs' => 'test_module#list_remote_diffs'
  # WORK WITH GIT REMOTES
  post 'test_module/info_git_remote'        => 'test_module#info_git_remote'
  post 'test_module/add_git_remote'         => 'test_module#add_git_remote'
  post 'test_module/remove_git_remote'      => 'test_module#remove_git_remote'

  # NODE_MODULE
  post 'node_module/add_user_direct_access' => 'account#add_user_direct_access'
  post 'node_module/info_about' => 'node_module#info_about'
  post 'node_module/pull_from_remote' => 'node_module#pull_from_remote'
  post 'node_module/update_model_from_clone' => 'node_module#update_model_from_clone'
  post 'node_module/delete' => 'node_module#delete'
  post 'node_module/delete_version' => 'node_module#delete_version'
  post 'node_module/info' => 'node_module#info'
  post 'node_module/list' => 'node_module#list'
  post 'node_module/pull_from_remote' => 'node_module#pull_from_remote'
  post 'node_module/remote_chmod' => 'node_module#remote_chmod'
  post 'node_module/remote_chown' => 'node_module#remote_chown'
  post 'node_module/confirm_make_public' => 'node_module#confirm_make_public'
  post 'node_module/remote_collaboration' => 'node_module#remote_collaboration'
  post 'node_module/list_remote_collaboration' => 'node_module#list_remote_collaboration'
  post 'node_module/list_remote' => 'node_module#list_remote'
  post 'node_module/versions' => 'node_module#versions'
  post 'node_module/create' => 'node_module#create'
  post 'node_module/import' => 'node_module#import'
  post 'node_module/import_version' => 'node_module#import_version'
  post 'node_module/delete_remote' => 'node_module#delete_remote'
  post 'node_module/export' => 'node_module#export'
  post 'node_module/get_remote_module_info' => 'node_module#get_remote_module_info'
  post 'node_module/get_workspace_branch_info' => 'node_module#get_workspace_branch_info'
  post 'node_module/update_from_initial_create' => 'node_module#update_from_initial_create'
  post 'node_module/list' => 'node_module#list'

  # DEPENDENCY
  post 'dependency/add_component_dependency' => 'dependency#add_component_dependency'

  # LIBRARY
  post 'library/list' => 'library#list'
  post 'library/info_about' => 'library#info_about'

  # METADATA
  get 'metadata/get_metadata/:metadata_file' => 'metadata#get_metadata'

  # NODE TEMPLATE
  post 'node/list' => 'node#list'
  post 'node/image_upgrade' => 'node#image_upgrade'
  post 'node/add_node_template' => 'node#add_node_template'
  post 'node/delete_node_template' => 'node#delete_node_template'

  # NODE INSTANCE
  post 'node/start' => 'node#start'
  post 'node/stop' => 'node#stop'
  # these commands right now should only be called wrt to assembly context
  # TODO: remove these from code and the methods that they only use
  #   post  'node/get_attributes' => 'node#get_attributes'
  #   post  'node/set_attributes' => 'node#set_attributes'
  #   post  'node/add_component' => 'node#add_component'
  #   post  'node/delete_component' => 'node#delete_component'
  #   post  'node/create_task' => 'node#create_task'
  #
  #   post  'node/info' => 'node#info'
  #   post  'node/info_about' => 'node#info_about'
  #   post  'node/destroy_and_delete' => 'node#destroy_and_delete'
  #   post  'node/get_op_status' => 'node#get_op_status'
  #
  #   post  'node/task_status' => 'node#task_status'
  #   post  'node/stage' => 'node#stage'
  #   post  'node/initiate_get_netstats' => 'node#initiate_get_netstats'
  #   post  'node/get_action_results' => 'node#get_action_results'
  #   post  'node/initiate_get_ps' => 'node#initiate_get_ps'
  #   post  'node/initiate_execute_tests' => 'node#initiate_execute_tests'

  # NODE_GROUP
  #   post  'node_group/list' => 'node_group#list'
  #   post  'node_group/get_attributes' => 'node_group#get_attributes '
  #   post  'node_group/set_attributes' => 'node_group#set_attributes'
  #   post  'node_group/task_status' => 'node_group#task_status'
  #   post  'node_group/create' => 'node_group#create'
  #   post  'node_group/delete' => 'node_group#delete'
  #   post  'node_group/info_about' => 'node_group#info_about'
  #   post  'node_group/get_members' => 'node_group#get_members'
  #   post  'node_group/add_component' => 'node_group#add_component'
  #   post  'node_group/delete_component' => 'node_group#delete_component'
  #   post  'node_group/create_task' => 'node_group#create_task'
  #   post  'node_group/set_default_template_node' => 'node_group#set_default_template_node'
  #   post  'node_group/clone_and_add_template_node' => 'node_group#clone_and_add_template_node'

  # PROJECT
  post 'project/list' => 'project#list'

  # REPO
  post 'repo/list' => 'repo#list'
  post 'repo/delete' => 'repo#delete'
  post 'repo/synchronize_target_repo' => 'repo#synchronize_target_repo'

  # SERVICE_MODULE
  post 'service_module/add_user_direct_access' => 'account#add_user_direct_access'
  post 'service_module/list_component_modules' => 'service_module#list_component_modules'
  post 'service_module/update_model_from_clone' => 'service_module#update_model_from_clone'
  post 'service_module/import' => 'service_module#import'
  post 'service_module/create' => 'service_module#create'
  post 'service_module/pull_from_remote' => 'service_module#pull_from_remote'
  post 'service_module/remote_chmod' => 'service_module#remote_chmod'
  post 'service_module/remote_chown' => 'service_module#remote_chown'
  post 'service_module/confirm_make_public' => 'service_module#confirm_make_public'
  post 'service_module/remote_collaboration' => 'service_module#remote_collaboration'
  post 'service_module/list_remote_collaboration' => 'service_module#list_remote_collaboration'
  post 'service_module/resolve_pull_from_remote' => 'service_module#resolve_pull_from_remote'
  post 'service_module/list' => 'service_module#list'
  post 'service_module/list_remote' => 'service_module#list_remote'
  post 'service_module/versions' => 'service_module#versions'
  post 'service_module/list_assemblies' => 'service_module#list_assemblies'
  post 'service_module/list_instances' => 'service_module#list_instances'
  post 'service_module/list_component_modules' => 'service_module#list_component_modules'
  post 'service_module/import_version' => 'service_module#import_version'
  post 'service_module/export' => 'service_module#export'
  post 'service_module/set_component_module_version' => 'service_module#set_component_module_version'
  post 'service_module/delete' => 'service_module#delete'
  post 'service_module/delete_version' => 'service_module#delete_version'
  post 'service_module/delete_remote' => 'service_module#delete_remote'
  post 'service_module/delete_assembly_template' => 'service_module#delete_assembly_template'
  post 'service_module/get_remote_module_info' => 'service_module#get_remote_module_info'
  post 'service_module/get_workspace_branch_info' => 'service_module#get_workspace_branch_info'
  post 'service_module/info' => 'service_module#info'
  post 'service_module/pull_from_remote' => 'service_module#pull_from_remote'
  post 'service_module/list_remote_diffs' => 'service_module#list_remote_diffs'
  post 'service_module/create_new_version' => 'service_module#create_new_version'
  post 'service_module/list_versions' => 'service_module#list_versions'
  post 'service_module/check_remote_exist' => 'service_module#check_remote_exist'

  # WORK WITH GIT REMOTES
  post 'service_module/info_git_remote'        => 'service_module#info_git_remote'
  post 'service_module/add_git_remote'         => 'service_module#add_git_remote'
  post 'service_module/remove_git_remote'      => 'service_module#remove_git_remote'

  # get   'service_module/workspace_branch_info/#{service_module_id.to_s}' => 'service_module#workspace_branch_info/#{service_module_id.to_s}'

  # STATE_CHANGE
  get 'state_change/list_pending_changes' => 'state_change#list_pending_changes'

  # TARGET
  post 'target/list' => 'target#list'
  post 'target/create' => 'target#create'
  post 'target/create_provider' => 'target#create_provider'
  post 'target/set_default' => 'target#set_default'
  post 'target/info_about' => 'target#info_about'
  post 'target/import_nodes' => 'target#import_nodes'
  post 'target/delete_and_destroy' => 'target#delete_and_destroy'
  post 'target/info' => 'target#info'
  post 'target/install_agents' => 'target#install_agents'
  post 'target/task_status' => 'target#task_status'
  post 'target/set_properties' => 'target#set_properties'

  # TASK
  post 'task/cancel_task' => 'task#cancel_task'
  post 'task/execute' => 'task#execute'
  post 'task/list' => 'task#list'
  post 'task/status' => 'task#status'
  post 'task/create_task_from_pending_changes' => 'task#create_task_from_pending_changes'

  # NAMESPACE
  post 'namespace/default_namespace_name' => 'namespace#default_namespace_name'
end

R8::Routes.freeze
