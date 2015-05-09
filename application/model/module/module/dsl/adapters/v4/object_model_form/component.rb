module DTK; class ModuleDSL; class V4
  class ObjectModelForm 
    class Component < OMFBase::Component
     private
      def body(input_hash,cmp,context={})
        ret = OutputHash.new
        cmp_type = ret["display_name"] = ret["component_type"] = qualified_component(cmp)
        # version below refers to component brranch version not metafile version
        ret["version"] = ::DTK::Component.default_version()
        ret["basic_type"] = "service"
        ret.set_if_not_nil("description",input_hash["description"])
        add_attributes!(ret,cmp_type,input_hash)
        opts = Hash.new
        add_dependent_components!(ret,input_hash,cmp_type,opts)
        ret.set_if_not_nil("component_include_module",include_modules?(input_hash,cmp_type,context))
        if opts[:constants]
          add_attributes!(ret,cmp_type,ret_input_hash_with_constants(opts[:constants]),:constant_attribute => true)
        end
        set_action_def_and_external_ref!(ret,input_hash,cmp,context)
        ret.set_if_not_nil("only_one_per_node",only_one_per_node(ret['external_ref']))
        ret
      end

      def set_action_def_and_external_ref!(ret,input_hash,cmp,context={})
        create_action = nil
        if action_def = ActionDef.new(cmp).convert_action_defs?(input_hash)
          create_action = action_def.delete_create_action!()
        end
        unless action_def.nil? or action_def.empty?
          ret["action_def"] = action_def
        end

        ret["external_ref"] =  
          if input_hash['external_ref'] then external_ref(input_hash['external_ref'],cmp) # this is for legacy
          elsif create_action then external_ref_from_create_action?(create_action,cmp)
          end
        unless ret["external_ref"]
          err_msg = "Cannot determine the create action in component '?1'"
          raise ParsingError.new(err_msg,component_print_form(cmp))
        end
        ret
      end

      def external_ref_from_create_action?(create_action,cmp)
        if DTK::ActionDef::Constant.matches?(create_action[:method_name],:CreateActionName)
          if create_action[:content].respond_to?(:external_ref_from_create_action)
            external_ref(create_action[:content].external_ref_from_create_action(),cmp)
          end
        end
      end

    end
  end
end; end; end

