module XYZ
  module ExportedResourceHandlerMixin
    class ExportedResourceHandler
      def self.create_attribute(exp_rsc_ps)
        klass = ret_klass(exp_rsc_ps[:name])
        klass.process(exp_rsc_ps)
      end
      def self.ret_klass(type)
        ret = nil
        begin
          ret = XYZ::ExportedResourceHandlerMixin.const_get "#{type.capitalize}ERH"
        rescue
          raise Error.new("processor for builtin type (#{type}) not treated yet")
        end
        ret  
      end
    end
    class FileERH < ExportedResourceHandler
      def self.process(exp_rsc_ps)
      #just want info from a few keys: title and tag
        #TODO: stub
#          pp {:source_ref => exp_rsc_ps[:paramters].map{|p|{p[:name] => p[:value].to_s}},
 #           :source_type => exp_rsc_ps.config_agent_type}
        
    
        nil
      end
    end 
  end
end
