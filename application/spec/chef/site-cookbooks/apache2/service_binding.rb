service :apache2_service do
  attribute "sap_config__l4",
   :semantic_type => {":array" => "sap_config__l4"},
   :type => "hash",
   :port_type => "input",
   :description => "apache2 ip listen portsK,service access point configuration",
   :type => "hash",
   :transform => 
    [{"port" => 80, "protocol" => "tcp"},
     {"port" => 443, "protocol" => "tcp"}]
end

