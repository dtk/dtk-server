require 'fog'
# TODO: get Fog to correct this
# monkey patch
class NilClass
  def blank?
   nil
  end
end
### end of monkey patch

module DTK
  class CloudConnect
    r8_nested_require('cloud_connect', 'ec2')
    r8_nested_require('cloud_connect', 'route53')

    #TODO: this should be moved to ec2 class because referencing R8::Config[:ec2]
    def get_compute_params(opts = {})
      ENV['FOG_RC'] ||= R8::Config[:ec2][:fog_credentials_path]
      ret = Fog.credentials()
      unless opts[:just_credentials]
        if region = R8::Config[:ec2][:region]
          ret = ret.merge(region: region)
        end
      end
      ret
    end

    private

    def hash_form(x)
      # this is supposed to fix [#<NoMethodError: undefined method `attributes' for #<Excon::Response:0x0000000529aec8>>,
      ret = nil
      if x
        if x.respond_to?(:attributes)
          ret = x.attributes
        elsif x.respond_to?(:data)
          ret = x.data
        end
      end
      if ret
        ret
      else
        response = (x ? x.inspect : 'nil')
        fail Error.new("Unexpected response: #{response}")
      end
    end

    # each service has its own mutex
    # LockRequest = {}
    def request_context(&_block)
      # TODO: think no need to use a mutex
      # TODO: put up in here some handling of errors such as ones that should be handled by doing a retry
      # lock = LockRequest[self.class] ||= Mutex.new
      # lock.synchronize { yield }
      yield
    end
  end
end

=begin
Put below in for Datfascia case, but in other contexts this seems to cause the non concurrency like behavior in ec2 requests
# excon monkey patch
require 'excon'
module Excon
  module Middleware
    class Expects < Excon::Middleware::Base
      def response_call(datum)
        if datum.has_key?(:expects) && ![*datum[:expects]].include?(datum[:response][:status])
          if datum[:response][:status] == 0
            ::DTK::Log.error("Monkey batch Excon::Middleware::Expects, stats 0 = 200")
            datum[:response][:status] = 200
          else
            raise(
              Excon::Errors.status_error(
                datum.reject {|key,value| key == :response},
                Excon::Response.new(datum[:response])
              )
            )
          end
        end
        @stack.response_call(datum)
      end
    end
  end
end
=end
