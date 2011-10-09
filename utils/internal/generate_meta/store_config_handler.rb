module XYZ
  module StoreConfigHandlerMixin
    class StoreConfigHandler
      extend TermStateHelpersMixin
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
      #can be overwritten
      def self.heuristic_to_guess_input_attr_key(source_ref)
        nil
      end
      def self.heuristic_to_guess_output_attr_key(source_ref)
        nil
      end
    end
    class FileERH < StoreConfigHandler
      def self.process_output_attr!(attr_meta,exp_rsc_ps)
        #set source ref
        resource_type = exp_rsc_ps[:name]
        source_ref = source_ref_object(exp_rsc_ps,resource_type)
        params = source_ref[:parameters] = exp_rsc_ps[:paramters]

        key = t(heuristic_to_guess_output_attr_key(source_ref)) || unknown
        attr_meta.set_hash_key(key)
        attr_meta[:display_name] = key
        attr_meta[:display_name] = unknown
        attr_meta[:description] = unknown
        attr_meta[:dynamic] = nailed(true)
        attr_meta[:external_ref] = unknown #TODO: stub; when known its factor var than put this val in external ref
        attr_meta[:source_ref] = source_ref.merge(:parameters => param_values_to_s(params))
      end
      def self.process_input_attr!(attr_meta,imp_coll_ps)
        #set source ref
        resource_type = imp_coll_ps[:type]
        source_ref = source_ref_object(imp_coll_ps,resource_type)
        attr_exprs = source_ref[:attr_exprs] = imp_coll_ps[:query].attribute_expressions()

        key = t(heuristic_to_guess_input_attr_key(source_ref)) || unknown
        attr_meta.set_hash_key(key)
        attr_meta[:display_name] = key
        attr_meta[:description] = unknown
        attr_meta[:external_ref] = unknown #TODO: stub; when known its factor var than put this val in external ref
        attr_meta[:source_ref] = source_ref.merge(:attr_exprs => attr_expr_values_to_s(attr_exprs))
      end
     private
      def self.param_values_to_s(params)
        params.map{|p|SimpleOrderedHash.new([{:name => p[:name]},{:value => p[:value].to_s}])}
      end
      def self.attr_expr_values_to_s(attr_exprs)
        attr_exprs.map{|a|SimpleOrderedHash.new([{:name => a[:name]},{:op => a[:op]},{:value => a[:value].to_s}])}
      end
      def self.heuristic_to_guess_output_attr_key(source_ref)
        tag_param = (source_ref[:parameters]||[]).find{|exp|exp[:name] == "tag"}
        tag_param[:value].to_s if tag_param
      end
      def self.heuristic_to_guess_input_attr_key(source_ref)
        tag_param = (source_ref[:attr_exprs]||[]).find{|exp|exp[:name] == "tag"}
        tag_param[:value].to_s if tag_param
      end
    end 
  end
end
