service :apache2_service do
  attribute "sap_config_ipv4",
   :semantic_type => {":array" => {"sap_config_ipv4" => {"application" => "webserver"}}},
   :type => "hash",
   :port_type => "input",
   :description => "apache2 ip service access point configuration",
   :type => "hash",
     :transform => 
     [{"ports" =>
        {"__ref"=>"node[apache2][listen_ports]"},
        "protocol"=> "tcp"}]
end

