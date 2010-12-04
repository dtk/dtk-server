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
  :semantic_type => {":array" => {"sap_config[ipv4]" => {"application" => "sql::mysql"}}},
    :transform =>
    [{
       "port" => 3306,
       "protocol" => "tcp",
       "application" => 
       {
         "db_created_on_server" => true
       }
     }]

  attribute "sap/socket",
    :recipes => ["mysql::server","mysql::server2"],
    :description => "mysql unix socket service access point",
    :semantic_type => {"sap[socket]" => {"application" => "sql::mysql"}},
    :type => "hash",
    :transform =>
      {
        "socket_file" => "/var/run/mysqld/mysqld.sock"
      }

  attribute "sap_config_for_slave",
    :recipes => ["mysql::master"],
    :type => "hash",
    :description => "mysql ip service access point configuration for slave",
    :semantic_type => {":array" => {"sap_config[ipv4]" => {"application" => "sql::mysql"}}},
    :transform =>
      [{
         "port" => 3306,
         "protocol" => "tcp",
         "application" => 
         {
           "db_created_on_server" => false,
           "username" => "slave",
           "database" => "mysql",
           "password" => {
             "__ref" => "node[mysql][server_root_password]"
           }
         },
         "constraints" => 
         {
           #put in contraint that this can just be attached to be slave
         }
      }]


  attribute "sap_ref_to_master",
    :recipes => ["mysql::slave"],
    :required => true,
    :type => "hash",
    :description => "mysql service access point reference for slave to connect with master",
    :semantic_type => {"sap_ref" => {"application" => "sql::mysql"}}

    
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
