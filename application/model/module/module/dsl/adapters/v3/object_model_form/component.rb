module DTK; class ModuleDSL; class V3
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
        external_ref = external_ref(input_hash.req(:external_ref),cmp)
        ret["external_ref"] = external_ref
        ret.set_if_not_nil("only_one_per_node",only_one_per_node(external_ref))
        add_attributes!(ret,cmp_type,input_hash)
        opts = {}
        add_dependent_components!(ret,input_hash,cmp_type,opts)
        section_name = "includes"
        ret.set_if_not_nil("component_include_module",include_modules?(input_hash,cmp_type,context))
        if opts[:constants]
          add_attributes!(ret,cmp_type,ret_input_hash_with_constants(opts[:constants]),constant_attribute: true)
        end
        ret
      end

      # processes "link_defs, "dependencies", and "component_order"
      def add_dependent_components!(ret,input_hash,base_cmp,opts={})
        dependencies,link_defs = Choice.deps_and_link_defs(input_hash,base_cmp,opts)
        ret.set_if_not_nil("dependency",dependencies)
        ret.set_if_not_nil("link_defs",link_defs)
        ret.set_if_not_nil("component_order",component_order(input_hash))
      end

      def include_modules?(input_hash,cmp_type,context={})
        section_name = 'includes'
        cmp_level_includes = input_hash[section_name]
        module_level_includes = context[:module_level_includes]
        if cmp_level_includes || module_level_includes
          module_context = context.merge(section_name: section_name)
          component_context = module_context.merge(component_type: cmp_type)
          if module_level_includes
            more_specific_incls = super(cmp_level_includes,component_context)
            less_specific_incls = super(module_level_includes,module_context)
            combine_includes(more_specific_incls,less_specific_incls)
          else
            super(cmp_level_includes,component_context)
          end
        end
      end

      def add_attr_data_type_attrs!(attr_props,info)
        type = info['type']||DefaultDatatype
        if type =~ /^array/
          nested_type = 'string'
          if type == 'array'
            type = 'array(string)'
          elsif type =~ /^array\((.+)\)$/
            nested_type = $1
          else
            raise ParsingError.new("Ill-formed attribute data type (?1)",type)
          end
          # TODO: this will be modified when clean up attribute properties for semantic dataype
          if AttributeSemanticType.isa?(nested_type)
            to_add = {
              "data_type" => AttributeSemanticType.datatype("array").to_s,
              "semantic_type_summary" => type,
              "semantic_type" => {":array" => nested_type},
              "semantic_data_type" => "array"
            }
            attr_props.merge!(to_add)
          end
        elsif AttributeSemanticType.isa?(type)
          attr_props.merge!("data_type" => AttributeSemanticType.datatype(type).to_s,"semantic_data_type" => type)
        end

        unless attr_props["data_type"]
          raise ParsingError.new("Ill-formed attribute data type (?1)",type)
        end
        attr_props
      end

      DefaultDatatype = "string"

      def dynamic_default_variable?(info)
        default_indicates_dynamic_default_variable?(info)
      end

      def value_asserted(info,attr_props)
        unless default_indicates_dynamic_default_variable?(info)
          ret = nil
          value = info["default"]
          unless value.nil?
            if semantic_data_type = attr_props["semantic_data_type"]
              # TODO: currently converting 'integer' -> integer and 'booelan' -> boolean; this may be unnecesary since the object model stores everything as strings
              ret = AttributeSemanticType.convert_and_raise_error_if_not_valid(semantic_data_type,value,attribute_name: attr_props['display_name'])
            end
            ret
          else
            nil #just to emphasize want to return nil when no value given
          end
        end
      end

      def default_indicates_dynamic_default_variable?(info)
        info["default"] == ExtRefDefaultPuppetHeader
      end
      ExtRefDefaultPuppetHeader = 'external_ref(puppet_header)'

      module AttributeSemanticType
        def self.isa?(semantic_type)
          apply('isa?'.to_sym,semantic_type)
        end
        def self.datatype(semantic_type)
          apply(:datatype,semantic_type)
        end
        def self.convert_and_raise_error_if_not_valid(semantic_type,value,opts={})
          apply(:convert_and_raise_error_if_not_valid,semantic_type,value,opts)
        end

        private

        def self.apply(*method_then_args)
          ::DTK::Attribute::SemanticDatatype.send(*method_then_args)
        end
      end
    end
  end
end; end; end
