class RestController < Controller
  helper :rest
  engine :none
  provide(:html, :type => 'text/html'){|a,s|s.to_json} 
  provide(:json, :type => 'application/json'){|a,s|s.to_json}

  def index
    rest_ok_response
  end
end
