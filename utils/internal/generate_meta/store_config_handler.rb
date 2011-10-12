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
        source_ref_object_base(parse_struct).merge(:resource_type => resource_type)
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
        name = nil
        exported_vars = nil #alternative is that export through exec piping to file
        #check if there is content field that has variables
        content_vars = content_variables_in_output_var(source_ref,attr_meta)
        if content_vars.size > 0
          name = content_vars.first if content_vars.size == 1 #TODO: stub; fine to have multiple vars
          exported_vars = content_vars
          pp "debug: multiple output vars in resource export: #{content_vars.size}" if content_vars.size > 1
        end
        name ||= heuristic_to_guess_output_attr_name(source_ref,attr_meta)
        attr_meta.set_hash_key(name)
        attr_meta[:field_name] = t(name)
        attr_meta[:description] = unknown
        attr_meta[:type] = t("string") #TODO: stub
        attr_meta[:dynamic] = nailed(true)

        ext_ref = SimpleOrderedHash.new(:name => name)
        ext_ref.merge!(:exported_vars => exported_vars) if exported_vars
        attr_meta[:external_ref] = t(ext_ref)

        attr_meta[:source_ref] = source_ref.merge(:parameters => param_values_to_s(params))
      end
      def self.process_input_attr!(attr_meta,imp_coll_ps)
        #set source ref
        resource_type = imp_coll_ps[:type]
        source_ref = source_ref_object(imp_coll_ps,resource_type)
        attr_exprs = source_ref[:attr_exprs] = imp_coll_ps[:query].attribute_expressions()

        name = heuristic_to_guess_input_attr_name(source_ref,attr_meta)
        attr_meta.set_hash_key(name)
        attr_meta[:field_name] = t(name)
        attr_meta[:description] = unknown
        attr_meta[:type] = t("string") #TODO: stub
        attr_meta[:external_ref] = t(SimpleOrderedHash.new(:name => name)) #TODO: stub; when known its factor var than put this val in external ref
        attr_meta[:source_ref] = source_ref.merge(:attr_exprs => attr_expr_values_to_s(attr_exprs))
      end
     private
      def self.param_values_to_s(params)
        params.map{|p|SimpleOrderedHash.new([{:name => p[:name]},{:value => p[:value].to_s}])}
      end
      def self.attr_expr_values_to_s(attr_exprs)
        attr_exprs.map{|a|SimpleOrderedHash.new([{:name => a[:name]},{:op => a[:op]},{:value => a[:value].to_s}])}
      end
      def self.heuristic_to_guess_output_attr_name(source_ref,attr_meta)
        tag_param = (source_ref[:parameters]||[]).find{|exp|exp[:name] == "tag"}
        ret_tag_value_or_gen_sym(tag_param,attr_meta)
      end
      def self.heuristic_to_guess_input_attr_name(source_ref,attr_meta)
        tag_param = (source_ref[:attr_exprs]||[]).find{|exp|exp[:name] == "tag"}
        ret_tag_value_or_gen_sym(tag_param,attr_meta)
      end

      def self.content_variables_in_output_var(source_ref,attr_meta)
        content = (source_ref[:parameters]||[]).find{|exp|exp[:name] == "content"}
        return Array.new unless content
        ret = content[:value] ? content[:value].variable_list() : nil
        return Array.new if ret.nil? or ret.empty?
        #prune variables that appear already; need parent source
        existing_attr_names = (attr_meta.parent_source||{})[:attributes].map{|a|a[:name]}
        ret.reject{|v|existing_attr_names.include?(v)}
      end

      def self.ret_tag_value_or_gen_sym(tag_param,attr_meta)
        if tag_param
          tag_param[:value].to_s(:just_variable_name => true) 
        else
          attr_num = attr_meta.attr_num
          raise Error.new("no tag param or attribute num") unless attr_num
          "attribute#{attr_num.to_s}"
        end
      end
    end 
  end
end
