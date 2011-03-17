service :postgresql do
  attribute "sap_config__l4",
    :recipes => ["postgresql::server"],
    :type => "hash",
    :description => "postgres ip service access point configuration",
    :semantic_type => {":array" =>"sap_config__l4"},
    :transform =>
    [{
       "port"  => 5432,
       "protocol" => "tcp"
     }]

  attribute "db_params",
    :recipes => ["postgresql::db"],
   :semantic_type => "db_params",
   :description => "Parameters for a db",
   :type => "hash"
end

