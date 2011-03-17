service :postgresql do
  attribute "sap_config__l4",
    :recipes => ["postgresql::server","postgresql::pgpool"],
    :type => "hash",
    :description => "postgres ip service access point configuration",
    :semantic_type => {":array" =>"sap_config__l4"},
    :transform =>
    [{
       "port"  => 5432,
       "protocol" => "tcp"
     }]

  attribute "conns_to_real_dbs",
    :recipes => ["postgresql::pgpool"],
    :type => "hash",
    :description => "postgres ip service access point configuration",
    :semantic_type => {":array" => "sap_ref__l4"},
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

