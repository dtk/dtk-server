module Ramaze::Helper
  module Rest
    def rest_response()
      unless @ctrl_results.kind_of?(BundleAndReturnHelper::ControllerResultsRest)
        raise Error.new("controller results is in wrong form; it should have 'rest' form")
      end
      JSON.generate(@ctrl_results)
    end

    def rest_ok_response(data={})
      RestResponse.new(:status => :ok,:data => data)
    end

    def rest_notok_response(errors=[{:code => :error}])
      if errors.kind_of?(Hash)
        errors = [errors]
      end
      RestResponse.new(:status => :notok, :errors => errors)
    end

    private
    class RestResponse < Hash
      def initialize(hash)
        replace(hash)
      end
      def is_ok?
        self[:status] == :ok
      end
      def data()
        self[:data]
      end
    end
  end
end
