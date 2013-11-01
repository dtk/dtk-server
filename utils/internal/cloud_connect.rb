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

    class GatedConnection
      def initialize(conn)
        @conn = conn
        #each service has its own mutex
        @mutex = Mutexs[self.class] ||= Mutex.new
      end

      def method_missing(name,*args,&block)
        @mutex.synchronize{@conn.send(name,*args,&block)
      end
      def respond_to?(name)
        @conn.respond_to?(name) || super
      end

      Mutexs = Hash.new
    end

  end 
end
