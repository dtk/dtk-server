module DTK
  class ModuleRefs
    class Parse < self
      def self.get_component_module_refs_dsl_info(module_class, module_branch, opts = {})
        module_class::DSLParser.parse_directory(module_branch, :component_module_refs, opts)
      end

      def self.update_component_module_refs_from_parse_objects(_module_class, module_branch, cmp_dsl_form_els)
        hash_content = semantic_parse(module_branch, cmp_dsl_form_els, include_nil_version: true)
        return hash_content if hash_content.is_a?(ErrorUsage::Parsing)
        update(module_branch, hash_content)
        ModuleRefs.new(module_branch, hash_content, content_hash_form_is_reified: true)
      end

      def self.update_component_module_refs(module_class, module_branch, opts = {})
        dsl_info = get_component_module_refs_dsl_info(module_class, module_branch, opts)
        return dsl_info if dsl_info.is_a?(ErrorUsage::Parsing)
        update_component_module_refs_from_parse_objects(module_class, module_branch, dsl_info)
      end

      private

      def self.semantic_parse(branch, dsl_info, opts={})
        ret = nil
        begin
          ret = reify_content(branch.model_handle(:model_ref), dsl_info, opts)
         rescue ErrorUsage::Parsing => e
          return e
         rescue => e
          #TODO: Logging to make sure that it is parse error and not code error
          Log.info_pp([e, e.backtrace[0..5]])
          return ErrorUsage::Parsing.new('Module refs parsing error')
        end
        ret
      end

      def self.reify_content(mh, object, opts = {})
        return {} unless object
        # if Hash type then this comes from querying the model ref table
        if object.is_a?(Hash)
          object.inject({}) do |h, (k, v)|
            if v.is_a?(ModuleRef)
              h.merge(k.to_sym => ModuleRef.reify(mh, v))
            else
              fail Error.new("Unexpected value associated with component module ref: #{v.inspect}")
            end
          end
          #This comes from parsing the dsl file
        elsif object.is_a?(ServiceModule::DSLParser::Output) || object.is_a?(ComponentDSLForm::Elements)
          object.inject({}) do |h, r|
            internal_form = convert_parse_to_internal_form(r, opts)
            h.merge(parse_form_module_name(r).to_sym => ModuleRef.reify(mh, internal_form))
          end
        else
          fail Error.new("Unexpected input (#{object.class})")
        end
      end

      def self.parse_form_module_name(parse_form_hash)
        ret = parse_form_hash[:component_module]
        ErrorUsage::Parsing.raise_error_if_not(ret, String,
                                               type: 'module name', for: 'component module ref')
        ret
      end

      def self.convert_parse_to_internal_form(parse_form_hash, opts = {})
        ret = {
          module_name: parse_form_hash[:component_module],
          module_type: 'component'
        }
        # TODO: should have dtk common return namespace_info instead of remote_namespace
        if namespace_info = parse_form_hash[:remote_namespace]
          ret[:namespace_info] = namespace_info
        end
        version_info = parse_form_hash[:version_info]
        if opts[:include_nil_version] or version_info
          ret[:version_info] = version_info
        end

        if external_ref = parse_form_hash[:external_ref]
          ret[:external_ref] = external_ref
        end

        ret
      end
    end
  end
end
