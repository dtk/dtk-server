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
    :description => "postgresql admin service access point reference to connect to server",
    :semantic_type => {"sap_ref" => {"application" => {"type" => "sql::postgresql"}}}

  attribute "db_config",
    :recipes => ["postgresql::db"],
    :type => "hash",
    :description => "postgres db",
    :semantic_type => {
      "db_config" => {
          "application" => {
             "type" => "sql::postgresql" 
      }}},
    :transform =>
    {
       "name"  => nil,
       "owner" => nil,
       "password" => nil
    }

  attribute "db_ref",
    :recipes => ["postgresql::single_tenant"],
    :required => true,
    :type => "hash",
    :description => "postgresql db connection",
    :semantic_type => {"db_ref" => {"application" => {"type" => "sql::postgresql"}}}

end

