require 'fog'
# TODO get Fog to correct this
# monkey patch
class NilClass
  def blank?
   nil
  end
end
### end of monkey patch

# Fog loads Excon
# bumped up time out from 60 to 180
Excon.defaults[:read_timeout] = 180

module DTK
  class CloudConnect
    r8_nested_require('cloud_connect','ec2')
    r8_nested_require('cloud_connect','route53')

    #TODO: this should be moved to ec2 class because referencing R8::Config[:ec2]
    def get_compute_params(opts={})
      ENV["FOG_RC"] ||= R8::Config[:ec2][:fog_credentials_path]
      ret = Fog.credentials()
      unless opts[:just_credentials]
        if region = R8::Config[:ec2][:region]
          ret = ret.merge(:region => region)
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
        raise Error.new("Unexpected response: #{response}")
      end
    end

    # each service has its own mutex
    LockRequest = Hash.new
    def request_context(&block)
      # TODO: put up in here some handling of errors such as ones that should be handled by doing a retry
      lock = LockRequest[self.class] ||= Mutex.new
      lock.synchronize{yield}
    end
  end 
end
