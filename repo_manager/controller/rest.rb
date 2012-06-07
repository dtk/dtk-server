class RestController < Controller
  helper :rest
  def index
    rest_ok_response
  end
end
