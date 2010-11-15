service :redis_service do
  attribute "sap_config/inet",
   :semantic_type => {"sap_config[inet]" => {"application" => "redis"}},
   :port_type => "input",
   :decription => "redis ip service access point configuration",
   :type => "hash",
     :transform => 
     [{"port" =>
        {"__ref"=>"node[redis][port]"},
        "protocol"=> "tcp"}]
end

