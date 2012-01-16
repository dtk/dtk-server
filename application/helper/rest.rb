module Ramaze::Helper
  module Rest
    def rest_response()
      #TODO: only handles case when there is one result
      res =  @ctrl_results.reject{|k,v|not(k.to_s =~ /^application/)}
      raise rest_response_error unless res.size == 1
      res.values.first[:content]
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
      {:content => item ? JSON.generate(item) : nil}
    end
  end
end
