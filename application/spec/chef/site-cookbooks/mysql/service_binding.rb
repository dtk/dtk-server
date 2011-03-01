service :mysql_server do
  attribute "monitor_user_id",
    :recipes => ["mysql::server","mysql::server2"],
    :monitoring_input => "true",
    :description => "db userid for monitoring application to use",
    :transform => "root"

  attribute "sap_config__l4",
    :recipes => ["mysql::server","mysql::server2"],
    :type => "hash",
    :description => "mysql ip service access point configuration",
    :semantic_type => {
      ":array" => {
        "sap_config__l4" => {
          "application" => {
            "type" => "sql::mysql", 
            "clients_provide_dbs" => true
          }}}},
    :transform =>
    [{
       "port" => {"__ref" => "node[mysql][port]"},
       "protocol" => "tcp"
     }]

  attribute "sap__socket",
    :recipes => ["mysql::server","mysql::server2"],
    :description => "mysql unix socket service access point",
    :semantic_type => {"sap__socket" => {"application" => {"type" => "sql::mysql"}}},
    :type => "hash",
    :transform =>
      {
        "socket_file" => "/var/run/mysqld/mysqld.sock"
      }

  attribute "sap_config_for_slave",
    :recipes => ["mysql::master"],
    :type => "hash",
    :description => "mysql ip service access point configuration for slave",
    :semantic_type => { 
      ":array" => {
        "sap_config__l4" => {
          "application" => {
            "type" => "sql::mysql", 
            "clients_provide_dbs" => false
        }}}},
    :transform => 
    [{
       "port" => {"__ref" => "node[mysql][port]"},
       "protocol" => "tcp",
       "application" => {
         "username" => "slave",
         "database" => "mysql",
         "password" => {
           "__ref" => "node[mysql][server_root_password]" #TODO: should use replicate user
         }
       },
       "constraints" => {}#put in constraint that this can just be attached to slave use
     }]

  attribute "sap_ref_to_master",
    :recipes => ["mysql::slave"],
    :required => true,
    :type => "hash",
    :description => "mysql service access point reference for slave to connect with master",
    :semantic_type => {"sap_ref__db" => {"application" => {"type" => "sql::mysql"}}}

    
  attribute "master_log_ref",
    :recipes => ["mysql::slave"],
    :required => true,
    :type => "hash",
    :description => "reference for mysql slave to get master log position",
    :semantic_type => "mysql_master_log_info"

  attribute "master_log",
    :recipes => ["mysql::master"],
    :required => true,
    :type => "hash",
    :description => "master log position",
    :semantic_type => "mysql_master_log_info"

end
