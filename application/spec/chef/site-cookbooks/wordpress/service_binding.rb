service :wordpress do
  attribute "sap_ref",
    :recipes => ["wordpress"],
    :required => true,
    :type => "hash",
    :description => "wordpress mysql service access point reference for client",
    :semantic_type => {"sap_ref" => {"application" => {"type" => "sql::mysql"}}},
    :transform => {
      "application" => {
        "username" => {"__ref" =>  "node[wordpress][db][user]"},
        "database" => {"__ref" =>  "node[wordpress][db][database]"},
        "password" => {"__ref" =>  "node[wordpress][db][password]"}
    }
  }
end
