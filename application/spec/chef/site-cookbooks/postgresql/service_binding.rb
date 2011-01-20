service :postgresql do
  attribute "sap_config_ipv4",
    :recipes => ["postgresql::server"],
    :type => "hash",
    :description => "postgres ip service access point configuration",
    :semantic_type => {
      ":array" => {
        "sap_config_ipv4" => {
          "application" => {
            "type" => "sql::postgresql" 
          }}}},
    :transform =>
    [{
       "port"  => 5432,
       "protocol" => "tcp"
     }]

  attribute "sap_ref",
    :recipes => ["postgresql::app"],
    :required => true,
    :type => "hash",
    :description => "postgresql service access point reference to connect to db",
    :semantic_type => {"sap_ref" => {"application" => {"type" => "sql::postgresql"}}}

end
