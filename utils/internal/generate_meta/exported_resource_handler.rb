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
          ret = XYZ.const_get "#{type.capitalize}ERH"
        rescue
          raise Error.new("processor for builtin type (#{type}) not treated yet")
        end
        ret  
      end
    end
    class FileERH < ExportedResourceHandler
      def self.process(exp_rsc_ps)
      #just want info from a few keys: title and tag
        pp exp_rsc_ps
        nil
      end
    end 
  end
end
