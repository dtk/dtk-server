service :postgresql do
  attribute "sap_config__l4",
    :recipes => ["postgresql::server"],
    :type => "hash",
    :description => "postgres ip service access point configuration",
    :semantic_type => {
      ":array" => {
        "sap_config__l4" => {
          "application" => {
            "type" => "sql::postgresql" 
          }}}},
    :transform =>
    [{
       "port"  => 5432,
       "protocol" => "tcp"
     }]

  attribute "sap_ref__l4",
    :recipes => ["postgresql::app"],
    :required => true,
    :type => "hash",
    :description => "postgresql admin service access point reference to connect to server",
    :semantic_type => {"sap_ref__l4" => {"application" => {"type" => "sql::postgresql"}}}

  attribute "sap_config__db",
    :recipes => ["postgresql::db"],
    :type => "hash",
    :description => "postgres db",
    :semantic_type => {
      "sap_config__db" => {
          "application" => {
             "type" => "sql::postgresql" 
      }}},
    :transform =>
    {
       "name"  => nil,
       "owner" => nil,
       "password" => nil
    }
  attribute "sap_config__db__admin",
    :recipes => ["postgresql::server"],
    :type => "hash",
    :description => "postgres db",
    :semantic_type => {
      "sap_config__db" => {
          "application" => {
             "type" => "sql::postgresql" 
      }}},
    :transform =>
    {
       "name"  => "admin",
       "owner" => "admin",
       "password" => nil
    }

  attribute "sap_ref__db",
    :recipes => ["postgresql::single_tenant"],
    :required => true,
    :type => "hash",
    :description => "postgresql db connection",
    :semantic_type => {"sap_ref__db" => {"application" => {"type" => "sql::postgresql"}}}

end

