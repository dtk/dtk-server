require 'fog'
# TODO get Fog to correct this
# monkey patch
class NilClass
  def blank?
   nil
  end
end
### end of monkey patch

module DTK
  class CloudConnect
    r8_nested_require('cloud_connect','ec2')
    r8_nested_require('cloud_connect','route53')

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
      x && x.attributes 
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
