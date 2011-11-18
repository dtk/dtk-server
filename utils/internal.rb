files = 
  [
   'dynamic_loader',
   'errors', 
   'auxiliary', 
   'sql', 
   'dataset_from_search_pattern', 
   'hash_object', 
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
   'repo', 
   'parse_log', 
   'current_session', 
   'create_thread', 
   'eventmachine_helper',
  ]
r8_nested_require('internal',files)

#just load base classes; specific models dynamically loaded on need basis
r8_nested_require('internal','data_sources') 

##monkey patches; shoudl be last
#TODO: make sure not patching dyanmically loaded classes
r8_nested_require('internal','timeout') 
