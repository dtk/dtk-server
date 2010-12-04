service :wordpress do
  attribute "sap_ref",
    :recipes => ["wordpress"],
    :required => true,
    :type => "hash",
    :description => "wordpress mysql service access point reference for client",
    :semantic_type => {"sap_ref" => {"application" => "sql::mysql"}},
    :transform =>
    [{
       "port" => nil,
       "protocol" => "tcp",
       "application" => 
       {
         "db_created_on_server" => true
       }
     }]

end
