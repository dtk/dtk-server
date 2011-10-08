module XYZ
  module StoreConfigHandlerMixin
    class StoreConfigHandler
      def self.set_output_attribute!(attribute_meta,exp_rsc_ps)
        klass = ret_klass(exp_rsc_ps[:name])
        klass.process_output_attr!(attribute_meta,exp_rsc_ps)
      end
      def self.set_intput_attribute!(attribute_meta,imp_coll_ps)
        klass = ret_klass(imp_coll_ps[:type])
        klass.process_input_attr!(attribute_meta,imp_coll_ps)
      end
      def self.ret_klass(type)
        ret = nil
        begin
          ret = XYZ::StoreConfigHandlerMixin.const_get "#{type.capitalize}ERH"
        rescue
          raise Error.new("processor for builtin type (#{type}) not treated yet")
        end
        ret  
      end
    end
    class FileERH < StoreConfigHandler
      def self.process_output_attr!(attr_meta,exp_rsc_ps)
      #just want info from a few keys: title and tag
        #TODO: stub
        attr_meta[:source_resource_type] = exp_rsc_ps[:name] 
        attr_meta[:source_ref] = exp_rsc_ps[:paramters].inject({}){|h,p|h.merge(p[:name] => p[:value].to_s)}
        attr_meta[:source_type] = exp_rsc_ps.config_agent_type.to_s
        #TODO: may haev super that does things like source type and source resource type
      end
      def self.process_input_attr!(attr_meta,imp_coll_ps)
        attr_meta[:test] = imp_coll_ps
      end
    end 
  end
end
