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
    end
    class FileERH < StoreConfigHandler
      def self.process_output_attr!(attr_meta,exp_rsc_ps)
        #set source ref
        name = nil
        exported_vars = nil #alternative is that export through exec piping to file
        #check if there is content field that has variables
        content_vars = content_variables_in_output_var(exp_rsc_ps,attr_meta)
        if content_vars.size > 0
          name = content_vars.first if content_vars.size == 1 #TODO: stub; fine to have multiple vars
          exported_vars = content_vars
          pp "debug: multiple output vars in resource export: #{content_vars.size}" if content_vars.size > 1
        end
        name ||= heuristic_to_guess_output_attr_name(exp_rsc_ps,attr_meta)
        attr_meta.set_hash_key(name)
        attr_meta[:field_name] = t(name)
        attr_meta[:description] = unknown
        attr_meta[:type] = t("string") #TODO: stub
        attr_meta[:dynamic] = nailed(true)

        ext_ref = SimpleOrderedHash.new(:name => name)
        ext_ref.merge!(:exported_vars => exported_vars) if exported_vars
        attr_meta[:external_ref] = t(ext_ref)
      end

      def self.process_input_attr!(attr_meta,imp_coll_ps)
        name = heuristic_to_guess_input_attr_name(imp_coll_ps,attr_meta)
        attr_meta.set_hash_key(name)
        attr_meta[:field_name] = t(name)
        attr_meta[:description] = unknown
        attr_meta[:type] = t("string") #TODO: stub
        attr_meta[:external_ref] = t(SimpleOrderedHash.new(:name => name)) #TODO: stub; when known its factor var than put this val in external ref
      end
     private
      def self.param_values_to_s(params)
        params.map{|p|SimpleOrderedHash.new([{:name => p[:name]},{:value => p[:value].to_s}])}
      end
      def self.attr_expr_values_to_s(attr_exprs)
        attr_exprs.map{|a|SimpleOrderedHash.new([{:name => a[:name]},{:op => a[:op]},{:value => a[:value].to_s}])}
      end
      def self.heuristic_to_guess_output_attr_name(exp_rsc_ps,attr_meta)
        tag_param = (exp_rsc_ps[:parameters]||[]).find{|exp|exp[:name] == "tag"}
        ret_tag_value_or_gen_sym(tag_param,attr_meta)
      end
      def self.heuristic_to_guess_input_attr_name(imp_coll_ps,attr_meta)
        attr_exprs = imp_coll_ps[:query].attribute_expressions()||[]
        tag_param = attr_exprs.find{|exp|exp[:name] == "tag"}
        ret_tag_value_or_gen_sym(tag_param,attr_meta)
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
