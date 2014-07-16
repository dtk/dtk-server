module DTK; class TestDSL; class GenerateFromImpl
  module StoreConfigHandlerMixin
    class StoreConfigHandler
      extend CommonMixin
      def self.set_output_attribute!(attribute_meta,exp_rsc_ps)
        klass = ret_klass(exp_rsc_ps[:name])
        klass.process_output_attr!(attribute_meta,exp_rsc_ps)
      end
      def self.set_intput_attribute!(attribute_meta,imp_coll_ps)
        klass = ret_klass(imp_coll_ps[:type])
        klass.process_input_attr!(attribute_meta,imp_coll_ps)
      end

      def self.add_attribute_mappings!(link_def_poss_link,data)
        resource_type = data[:attr_imp_coll].source_ref[:type]
        klass = ret_klass(resource_type)
        klass.process_storeconfig_attr_mapping!(link_def_poss_link,data)
        klass.process_extra_attr_mappings!(link_def_poss_link,data)
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
        # resassign hash_key because attr_meta.set_hash_key can renumber for dups
        hash_key = attr_meta.set_hash_key(hash_key)
        name = hash_key
        attr_meta[:include] = nailed(true)
        attr_meta[:field_name] = t(name)
        attr_meta[:description] = unknown
        attr_meta[:type] = t("string") #TODO: stub
        attr_meta[:dynamic] = nailed(true)
        ext_ref = create_external_ref(name,"puppet_exported_resource")
        augment_ext_ref_for_output_attr!(ext_ref,exp_rsc_ps)
        attr_meta[:external_ref] = nailed(ext_ref)
      end

      def self.process_input_attr!(attr_meta,imp_coll_ps)
        hash_key = hash_key_for_input_attr(imp_coll_ps)
        # resassign hash_key because attr_meta.set_hash_key can renumber for dups
        hash_key = attr_meta.set_hash_key(hash_key)
        name = hash_key
        attr_meta[:include] = nailed(true)
        attr_meta[:field_name] = t(name)
        attr_meta[:description] = unknown
        attr_meta[:type] = t("string") #TODO: stub
        ext_ref = create_external_ref(name,"puppet_imported_collection")
        augment_ext_ref_for_input_attr!(ext_ref,imp_coll_ps)
        attr_meta[:external_ref] = nailed(ext_ref)
      end

      def self.process_storeconfig_attr_mapping!(link_def_poss_link,data)
        attr_mappings = link_def_poss_link[:attribute_mappings] ||= MetaArray.new
        input = {:component => data[:attr_imp_coll].parent.hash_key, :attribute => data[:attr_imp_coll].hash_key}
        output = {:component => data[:attr_exp_rsc].parent.hash_key, :attribute => data[:attr_exp_rsc].hash_key}
        attr_mappings << link_def_poss_link.create_attribute_mapping(input,output,{:include => true})
      end

      def self.process_extra_attr_mappings!(link_def_poss_link,data)
        matching_vars = data[:matching_vars]
        return if matching_vars.nil? or matching_vars.empty?
        matching_vars.each{|match|process_extra_attr_mapping!(link_def_poss_link,match,data)}
      end

      def self.hash_key_for_output_attr(exp_rsc_ps)
        title_param = (exp_rsc_ps[:parameters]||[]).find{|exp|exp[:name] == "title"}
        sanitize_attribute("#{exp_rsc_ps[:name]}--#{title_param[:value].to_s(:just_variable_name => true)}")
      end
      def self.augment_ext_ref_for_output_attr!(ext_ref,exp_rsc_ps)
        title_param = (exp_rsc_ps[:parameters]||[]).find{|exp|exp[:name] == "title"}
        ext_ref["resource_type"] = exp_rsc_ps[:name]
        ext_ref["title_with_vars"] = title_param[:value].structured_form()
        ext_ref
      end

      def self.hash_key_for_input_attr(imp_coll_ps)
        attr_exprs = imp_coll_ps[:query].attribute_expressions()||[]
        postfix = attr_exprs.map{|a|"#{a[:name]}__#{a[:value].to_s(:just_variable_name => true)}"}.join("--")
        sanitize_attribute("#{imp_coll_ps[:type]}--#{postfix}")
      end
      def self.augment_ext_ref_for_input_attr!(ext_ref,imp_coll_ps)
        ext_ref["resource_type"] = imp_coll_ps[:type]
        # TODO: think can deprecate
        # ext_ref["import_coll_query"] = imp_coll_ps[:query].structured_form()
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
        # prune variables that appear already; need parent source
        existing_attr_names = (attr_meta.parent_source||{})[:attributes].map{|a|a[:name]}
        ret.reject{|v|existing_attr_names.include?(v)}
      end
    end
    class FileERH < StoreConfigHandler
      def self.process_extra_attr_mapping!(link_def_poss_link,match,data)
        attr_mappings = link_def_poss_link[:attribute_mappings] ||= MetaArray.new
        return unless match[:name] == "tag" and match[:input_var].is_variable? and match[:output_var].is_variable?
        input_component = data[:attr_imp_coll].parent.hash_key
        input = {:component =>  input_component,:attribute => match[:input_var][:value]}
        output_component = data[:attr_exp_rsc].parent.hash_key
        output = {:component =>  output_component,:attribute => match[:output_var][:value]}
        attr_mappings << link_def_poss_link.create_attribute_mapping(input,output)
      end
    end
  end
end; end; end
