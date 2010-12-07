service :nagios do
  attribute "monitored_client_sap_config",
    :recipes => ["nagios::client"],
    :required => true,
    :type => "hash",
    :description => "monitored client service access point",
    :semantic_type => {"sap_config[ipv4]" => {"application" => {"type" => "nrpe"}}},
    :transform => {
      "port" => "5666",
      "protocol" => "tcp"
    }

  attribute "monitor_sap_refs",
    :recipes => ["nagios::server"],
    :required => true,
    :type => "hash",
    :description => "monitor client service access point ref",
    :semantic_type => {":array" => {"sap_ref" => {"application" => {"type" => "nrpe"}}}}
end
