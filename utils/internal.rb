files = 
  [
   'dynamic_loader',
   'auxiliary', 
   'sql', 
   'aes', 
   'dataset_from_search_pattern', 
   'hash_object', 
   'opts',
   'array_object', 
   'rest_uri', 
   'serialize_to_json', 
   'import_export', 
   'semantic_type', 
   'workflow', 
   'command_and_control', 
   'config_agent', 
   'cloud_connect', 
   'view_def_processor', 
   'repo_manager', 
   'parse_log', 
   'current_session', 
   'create_thread', 
   'eventmachine_helper',
   'extract',
   'action_results_queue',
   'simple_action_queue',
   'async_response',
   'output_table'
  ]
r8_nested_require('internal',files)

r8_nested_require('internal/workflow/adapters', 'agent_grit_adapter')

#just load base classes; specific models dynamically loaded on need basis
r8_nested_require('internal','data_sources') 

##monkey patches; shoudl be last
#TODO: make sure not patching dyanmically loaded classes
r8_nested_require('internal','timeout') 
