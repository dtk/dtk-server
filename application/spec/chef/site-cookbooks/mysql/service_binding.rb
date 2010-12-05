service :mysql_server do
  attribute "db_info",
    :recipes => ["mysql::server","mysql::server2"],
    :monitoring_input => "true",
    :type => "hash",
    :semantic_type => {":array"  => "db_info"},
    :transform =>
      [{
         "username" => "root",
         "database" => "mysql",
         "password" => {
           "__ref" => "node[mysql][server_root_password]"
         }
       }
      ]
  attribute "monitor_user_id",
    :recipes => ["mysql::server","mysql::server2"],
    :monitoring_input => "true",
    :description => "db userid for monitoring application to use",
    :transform => "root"

  attribute "sap_config/ipv4",
    :recipes => ["mysql::server","mysql::server2"],
    :type => "hash",
    :description => "mysql ip service access point configuration",
    :semantic_type => {":array" => {"sap_config[ipv4]" => {"application" => {"type" => "sql::mysql", "db_created_on_server" => true}}}},
    :transform =>
    [{
       "port" => 3306,
       "protocol" => "tcp"
     }]

  attribute "sap/socket",
    :recipes => ["mysql::server","mysql::server2"],
    :description => "mysql unix socket service access point",
    :semantic_type => {"sap[socket]" => {"application" => {"type" => "sql::mysql"}}},
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
        "sap_config[ipv4]" => {
          "application" => {
            "type" => "sql::mysql", 
            "db_created_on_server" => false,
            "constraints" => {}#put in contraint that this can just be attached to slave use
        }}}},
    :transform => 
    [{
       "port" => 3306,
       "protocol" => "tcp",
       "application" => {
         "username" => "slave",
         "database" => "mysql",
         "password" => {
           "__ref" => "node[mysql][server_root_password]" #TODO: should use replicate user
         }
       }
     }]

  attribute "sap_ref_to_master",
    :recipes => ["mysql::slave"],
    :required => true,
    :type => "hash",
    :description => "mysql service access point reference for slave to connect with master",
  :semantic_type => {"sap_ref" => {"application" => {"type" => "sql::mysql"}}}

    
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
