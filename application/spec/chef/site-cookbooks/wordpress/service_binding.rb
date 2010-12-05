service :wordpress do
  attribute "sap_ref",
    :recipes => ["wordpress"],
    :required => true,
    :type => "hash",
    :description => "wordpress mysql service access point reference for client",
    :semantic_type => {"sap_ref" => {"application" => {"type" => "sql::mysql"}}}

end
