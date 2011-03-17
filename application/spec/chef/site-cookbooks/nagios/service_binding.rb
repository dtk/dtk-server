service :nagios do
  attribute "sap_config__l4",
    :recipes => ["nagios::client"],
    :required => true,
    :type => "hash",
    :description => "monitored client service access point",
    :semantic_type => "sap_config__l4",
    :transform => {
      "port" => "5666",
      "protocol" => "tcp"
    }

  attribute "sap_ref__l4",
    :recipes => ["nagios::server"],
    :required => true,
    :type => "hash",
    :description => "monitor client service access point ref",
    :semantic_type => {":array" => "sap_ref__l4"}
end
