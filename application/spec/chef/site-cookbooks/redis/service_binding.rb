service :redis_service do
  attribute "sap_config__l4",
   :semantic_type => {":array" => {"sap_config__l4" => {"application" => "redis"}}},
   :type => "hash",
   :port_type => "input",
   :description => "redis ip service access point configuration",
   :type => "hash",
     :transform => 
     [{"port" =>
        {"__ref"=>"node[redis][port]"},
        "protocol"=> "tcp"}]
end

