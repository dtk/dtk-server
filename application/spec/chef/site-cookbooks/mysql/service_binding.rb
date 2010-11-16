service :mysql_server do
  attribute "db_info",
    :recipes => ["mysql::server","mysql::server2"],
    :monitoring_input => "true",
    :type => "hash",
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
    :port_type => "input",
    :type => "hash",
    :description => "mysql ip service access point configuration",
    :semantic_type => {":array" => {"sap_config[ipv4]" => {"application" => "sql::mysql"}}},
    :transform =>
      [{
        "port" => 3306,
        "protocol" => "tcp",
        "binding_addr_constraints" => [
        ]
      }]

  attribute "sap/socket",
    :recipes => ["mysql::server","mysql::server2"],
    :port_type => "input",
    :description => "mysql unix socket service access point",
    :semantic_type => {"sap[socket]" => {"application" => "sql::mysql"}},
    :type => "hash",
    :transform =>
      {
        "socket_file" => "/var/run/mysqld/mysqld.sock"
      }
    

  attribute "sap_ref",
    :recipes => ["mysql::client_app1"],
    :port_type => "output",
    :required => true,
    :type => "hash",
    :description => "mysql service access point reference for client",
    :semantic_type => {"sap_ref" => {"application" => "sql::mysql"}}
end
