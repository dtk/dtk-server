service :postgresql do
  attribute "sap_config/ipv4",
    :recipes => ["postgresql::server"],
    :type => "hash",
    :description => "postgres ip service access point configuration",
    :semantic_type => {
      ":array" => {
        "sap_config[ipv4]" => {
          "application" => {
            "type" => "sql::postgresql" 
          }}}},
    :transform =>
    [{
       "port"  => 5432,
       "protocol" => "tcp"
     }]
end
