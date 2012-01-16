module Ramaze::Helper
  module Rest
    def rest_response()
      JSON.generate(@ctrl_results)
    end

    def rest_ok_response(data={})
      wrap_rest_response(:status => :ok,:data => data)
    end

    def rest_notok_response(errors=[{:code => :error}])
      if errors.kind_of?(Hash)
        errors = [errors]
      end
      wrap_rest_response(:status => :notok, :errors => errors)
    end

    private
    def wrap_rest_response(item)
      item
    end
  end
end
