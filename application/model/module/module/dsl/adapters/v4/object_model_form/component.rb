module DTK; class ModuleDSL; class V4
  class ObjectModelForm 
    class Component < OMFBase::Component
     private
      def body(input_hash,cmp,context={})
        ret = OutputHash.new
        cmp_type = ret["display_name"] = ret["component_type"] = qualified_component(cmp)
        ret["basic_type"] = "service"
        ret.set_if_not_nil("description",input_hash["description"])
        add_attributes!(ret,cmp_type,input_hash)
        opts = Hash.new
        add_dependent_components!(ret,input_hash,cmp_type,opts)
        section_name = "includes"
        ret.set_if_not_nil("component_include_module",include_modules?(input_hash,cmp_type,context))
        if opts[:constants]
          add_attributes!(ret,cmp_type,ret_input_hash_with_constants(opts[:constants]),:constant_attribute => true)
        end
        set_action_def_and_external_ref!(ret,input_hash,cmp,context)
        ret.set_if_not_nil("only_one_per_node",only_one_per_node(ret['external_ref']))
        ret
      end

      def set_action_def_and_external_ref!(ret,input_hash,cmp,context={})
        action_def = ActionDef.new(cmp).convert_action_defs?(input_hash)
        if create_action = action_def.delete_create_action!()
        end
        unless action_def.nil? or action_def.empty?
          ret["action_def"] = action_def
        end
        external_ref = external_ref(input_hash.req(:external_ref),cmp)
        ret["external_ref"] = external_ref(input_hash.req(:external_ref),cmp)
        ret
      end

    end
  end
end; end; end
