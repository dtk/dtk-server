module Ramaze::Helper
  module Common
    def ret_request_params(*params)
      return nil unless request_method_is_post?()
      return request.params if params.size == 0
      ret = params.map{|p|request.params[p.to_s]}
      ret.size == 1 ? ret.first : ret
    end

    def ret_non_null_request_params(*params)
      return nil unless request_method_is_post?()
      null_params = Array.new
      ret = params.map do |p|
        unless val = request.params[p.to_s]
          null_params << p
        else val
        end
      end
      raise_error_null_params?(*null_params)
      ret.size == 1 ? ret.first : ret
    end

    def raise_error_null_params?(*null_params)
      unless null_params.empty?
        raise ::R8::RepoManager::Error.new("These parameters should not be null (#{null_params.join(",")})")
      end
    end

    def request_method_is_get?()
      request.env["REQUEST_METHOD"] == "GET"
    end
    def request_method_is_post?()
      request.env["REQUEST_METHOD"] == "POST"
    end
  end
end

