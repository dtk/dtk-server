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
     private
      def self.ret_klass(type)
        ret = nil
        begin
          ret = XYZ::StoreConfigHandlerMixin.const_get "#{type.capitalize}ERH"
        rescue
          raise Error.new("processor for builtin type (#{type}) not treated yet")
        end
        ret  
      end

      def self.process_output_attr!(attr_meta,exp_rsc_ps)
        hash_key = hash_key_for_output_attr(exp_rsc_ps)
        #resassign hash_key because attr_meta.set_hash_key can renumber for dups
        hash_key = attr_meta.set_hash_key(hash_key)
        name = hash_key
        attr_meta[:field_name] = t(name)
        attr_meta[:description] = unknown
        attr_meta[:type] = t("string") #TODO: stub
        attr_meta[:dynamic] = nailed(true)
        ext_ref = SimpleOrderedHash.new(:name => name)
        augment_ext_ref_for_output_attr!(ext_ref,exp_rsc_ps)
        attr_meta[:external_ref] = nailed(ext_ref)
      end

      def self.process_input_attr!(attr_meta,imp_coll_ps)
        hash_key = hash_key_for_input_attr(imp_coll_ps)
        #resassign hash_key because attr_meta.set_hash_key can renumber for dups
        hash_key = attr_meta.set_hash_key(hash_key)
        name = hash_key
        attr_meta[:field_name] = t(name)
        attr_meta[:description] = unknown
        attr_meta[:type] = t("string") #TODO: stub
        ext_ref = SimpleOrderedHash.new(:name => name) 
        augment_ext_ref_for_input_attr!(ext_ref,imp_coll_ps)
        attr_meta[:external_ref] = nailed(ext_ref)
      end

      def self.hash_key_for_output_attr(exp_rsc_ps)
        title_param = (exp_rsc_ps[:parameters]||[]).find{|exp|exp[:name] == "title"}
        "#{exp_rsc_ps[:name]}--#{title_param[:value].to_s(:just_variable_name => true)}"
      end
      def self.augment_ext_ref_for_output_attr!(ext_ref,exp_rsc_ps)
        title_param = (exp_rsc_ps[:parameters]||[]).find{|exp|exp[:name] == "title"}
        ext_ref[:resource_type] = exp_rsc_ps[:name]
        ext_ref[:title_with_vars] = title_param[:value].to_s()
        ext_ref
      end

      def self.hash_key_for_input_attr(imp_coll_ps)
        attr_exprs = imp_coll_ps[:query].attribute_expressions()||[]
        postfix = attr_exprs.map{|a|"#{a[:name]}__#{a[:value].to_s(:just_variable_name => true)}"}.join("--")
        "#{imp_coll_ps[:type]}--#{postfix}"
      end
      def self.augment_ext_ref_for_input_attr!(ext_ref,imp_coll_ps)
        ext_ref[:resource_type] = imp_coll_ps[:type]
        ext_ref[:import_coll_query] = imp_coll_ps[:query].array_form()
        ext_ref
      end

      def self.param_values_to_s(params)
        params.map{|p|SimpleOrderedHash.new([{:name => p[:name]},{:value => p[:value].to_s}])}
      end
      def self.attr_expr_values_to_s(attr_exprs)
        attr_exprs.map{|a|SimpleOrderedHash.new([{:name => a[:name]},{:op => a[:op]},{:value => a[:value].to_s}])}
      end


      def self.content_variables_in_output_var(exp_rsc_ps,attr_meta)
        content = (exp_rsc_ps[:parameters]||[]).find{|exp|exp[:name] == "content"}
        return Array.new unless content and content[:value]
        
        if template = content[:value].template?()
          pp "debug: handle content with template #{template.to_s}"
          return Array.new
        end
        ret = content[:value].variable_list()
        return Array.new if ret.empty?
        #prune variables that appear already; need parent source
        existing_attr_names = (attr_meta.parent_source||{})[:attributes].map{|a|a[:name]}
        ret.reject{|v|existing_attr_names.include?(v)}
      end
    end
    class FileERH < StoreConfigHandler
    end 
  end
end
