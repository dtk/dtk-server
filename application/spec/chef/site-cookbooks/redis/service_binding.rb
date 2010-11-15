service :redis_service do
  attribute "sap_config",
   :semantic_type => "sap_config",
   :type => "hash",
   :required => true,
   :transform => 
     [{"port" =>
        {"__ref"=>"node[redis][port]"},
        "protocol"=> "tcp",
        "type"=>"inet"}]
end

