service :wordpress do
  attribute "sap_ref",
    :recipes => ["wordpress"],
    :required => true,
    :type => "hash",
    :description => "wordpress service access point reference",
    :semantic_type => {"sap_ref" => {"application" => {"type" => "sql"}}}
  }
end
