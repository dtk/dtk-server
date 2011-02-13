service :wordpress do
  attribute "sap_ref__l4",
    :recipes => ["wordpress"],
    :required => true,
    :type => "hash",
    :description => "wordpress service access point reference",
    :semantic_type => {"sap_ref__l4" => {"application" => {"type" => "sql"}}}
end
