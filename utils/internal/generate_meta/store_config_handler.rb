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
      private
      def self.source_ref_object(parse_struct,resource_type)
        SimpleOrderedHash.new([{:config_agent_type => parse_struct.config_agent_type.to_s},{:resource_type => resource_type}])
      end

    end
    class FileERH < StoreConfigHandler
      def self.process_output_attr!(attr_meta,exp_rsc_ps)
      #just want info from a few keys: title and tag
        #TODO: stub
        resource_type = exp_rsc_ps[:name]
        source_ref = source_ref_object(exp_rsc_ps,resource_type)
        source_ref[:parameters] = exp_rsc_ps[:paramters].inject({}){|h,p|h.merge(p[:name] => p[:value].to_s)}
        attr_meta[:source_ref] = source_ref
      end
      def self.process_input_attr!(attr_meta,imp_coll_ps)
        resource_type = imp_coll_ps[:type]
        source_ref = source_ref_object(imp_coll_ps,resource_type)
        source_ref[:parameters] = imp_coll_ps[:query] #TODO: stub
        attr_meta[:source_ref] = source_ref
      end
    end 
  end
end
