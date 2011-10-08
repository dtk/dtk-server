module XYZ
  module ExportedResourceHandlerMixin
    class ExportedResourceHandler
      def self.set_attribute!(attribute_meta,exp_rsc_ps)
        klass = ret_klass(exp_rsc_ps[:name])
        klass.process!(attribute_meta,exp_rsc_ps)
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
      def self.process!(attr_meta,exp_rsc_ps)
      #just want info from a few keys: title and tag
        #TODO: stub
        attr_meta[:source_ref] = exp_rsc_ps[:paramters].map{|p|{p[:name] => p[:value].to_s}}
        attr_meta[:source_type] = exp_rsc_ps.config_agent_type
      end
    end 
  end
end
