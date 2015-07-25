module DTK; class ModuleDSL; class V3
  class ObjectModelForm
    class Component < OMFBase::Component
      private

      def body(input_hash, cmp, context = {})
        ret = OutputHash.new
        cmp_type = ret['display_name'] = ret['component_type'] = qualified_component(cmp)
        # version below refers to component brranch version not metafile version
        ret['version'] = ::DTK::Component.default_version()
        ret['basic_type'] = 'service'
        ret.set_if_not_nil('description', input_hash['description'])
        external_ref = external_ref(input_hash.req(:external_ref), cmp)
        ret['external_ref'] = external_ref
        ret.set_if_not_nil('only_one_per_node', only_one_per_node(external_ref))
        add_attributes!(ret, cmp_type, input_hash)
        opts = {}
        add_dependent_components!(ret, input_hash, cmp_type, opts)
        section_name = 'includes'
        ret.set_if_not_nil('component_include_module', include_modules?(input_hash, cmp_type, context))
        if opts[:constants]
          add_attributes!(ret, cmp_type, ret_input_hash_with_constants(opts[:constants]), constant_attribute: true)
        end
        ret
      end

      # processes "link_defs, "dependencies", and "component_order"
      def add_dependent_components!(ret, input_hash, base_cmp, opts = {})
        dependencies, link_defs = Choice.deps_and_link_defs(input_hash, base_cmp, opts)
        ret.set_if_not_nil('dependency', dependencies)
        ret.set_if_not_nil('link_defs', link_defs)
        ret.set_if_not_nil('component_order', component_order(input_hash))
      end

      def include_modules?(input_hash, cmp_type, context = {})
        section_name = 'includes'
        cmp_level_includes = input_hash[section_name]
        module_level_includes = context[:module_level_includes]
        if cmp_level_includes || module_level_includes
          module_context = context.merge(section_name: section_name)
          component_context = module_context.merge(component_type: cmp_type)
          if module_level_includes
            more_specific_incls = super(cmp_level_includes, component_context)
            less_specific_incls = super(module_level_includes, module_context)
            combine_includes(more_specific_incls, less_specific_incls)
          else
            super(cmp_level_includes, component_context)
          end
        end
      end

    end
  end
end; end; end
