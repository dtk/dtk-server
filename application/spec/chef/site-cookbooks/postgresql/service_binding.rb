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

  attribute "pg_pool_sap_config__l4",
    :recipes => ["postgresql::pgpool"],
    :type => "hash",
    :description => "postgres ip service access point configuration",
    :semantic_type => "sap_config__l4",
    :transform =>
    {
       "port"  => 5432,
       "protocol" => "tcp"
     }

  attribute "pg_pool_sap_ref__l4",
    :recipes => ["postgresql::pgpool"],
    :type => "hash",
    :description => "postgres ip service access point configuration",
    :semantic_type => {":array" => "sap_ref__l4"},
    :transform =>
    [{
       "port"  => 5432,
       "protocol" => "tcp"
     }],
     :dependency  => {
       "attribute_constraint" => {
         "display_name"=> "component_constraint",
         "type"=> "component",
         "search_pattern"=> {
           ":filter"=> [":eq",":specific_type","postgres_db_server"]
         },
         "description" =>  "Not connecting to Postgres Server"
       }
     }

  attribute "db_params",
    :recipes => ["postgresql::db"],
   :semantic_type => "db_params",
   :description => "Parameters for a db",
   :type => "hash"
end

