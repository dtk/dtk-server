service :haproxy do
  attribute "sap_config__l4",
    :recipes => ["haproxy"],
    :type => "hash",
    :description => "service access point configuration",
    :semantic_type => {":array" =>"sap_config__l4"},
    :transform =>
    [{"port"  => 80, "protocol" => "tcp"},
     {"port"  => 443, "protocol" => "tcp"}]

  attribute "conns_to_real_servers",
    :recipes => ["haproxy"],
    :type => "hash",
    :description => "service access point configuration",
    :semantic_type => {":array" => "sap_ref__l4"}
end

