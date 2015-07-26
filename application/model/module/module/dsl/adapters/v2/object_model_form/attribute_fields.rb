module DTK; class ModuleDSL; class V2
  class ObjectModelForm
    class AttributeFields < self
      def self.convert(parent, attr_name, info, opts = {})
        ret = OutputHash.new('display_name' => attr_name)
        side_effect_settings = {}

        if dynamic_default_variable?(info)
          side_effect_settings.merge!('dynamic' => true)
        end

        # set external refs
        if parent.kind_of?(Component)
          external_ref = 
            if opts[:constant_attribute] || info['constant']
              side_effect_settings.merge!(Attribute::Constant.side_effect_settings())
              Attribute::Constant.ret_external_ref()
            else
              external_ref_component_not_constant(attr_name, info, opts)
            end
          ret.merge!('external_ref' => external_ref)
        end

        add_attr_data_type_attrs!(ret, info)

        # setting even when nil so on change can cancel old value
        ret['value_asserted'] = value_asserted(info, ret)
        
        side_effect_settings.each_pair { |field, value| ret[field] ||= value }

        Default.add_defaults_for_nils!(ret, info)

        ret
      end

      private

      def self.dynamic_default_variable?(info)
        info['default'] == ExtRefDefaultPuppetHeader
      end
      ExtRefDefaultPuppetHeader = 'external_ref(puppet_header)'

      def self.external_ref_component_not_constant(attr_name, info, opts = {})
        type = 'puppet_attribute' #TODO: hardwired; type and path probably not needed; ws put in for Chef 
        unless cmp_type = opts[:component_type]
          Log.error("Unexpected that opts[:component_type] is nil")
        end
        external_ref_name = (info['external_ref'] || {})[type] || attr_name
        {
          'type' => type,
          'path' => "node[#{cmp_type}][#{external_ref_name}]"
        }.merge(opts[:dynamic_default_variable] ? { 'default_variable' => true } : {})
      end
      
      def self.add_attr_data_type_attrs!(attr_fields, info)
        type = info['type'] || Default::Datatype
        if type =~ /^array/
          nested_type = 'string'
          if type == 'array'
            type = 'array(string)'
          elsif type =~ /^array\((.+)\)$/
            nested_type = Regexp.last_match(1)
          else
            fail ParsingError.new('Ill-formed attribute data type (?1)', type)
          end
          # TODO: this will be modified when clean up attribute properties for semantic dataype
          if AttributeSemanticType.isa?(nested_type)
            to_add = {
              'data_type' => AttributeSemanticType.datatype('array').to_s,
              'semantic_type_summary' => type,
              'semantic_type' => { ':array' => nested_type },
              'semantic_data_type' => 'array'
            }
            attr_fields.merge!(to_add)
          end
        elsif AttributeSemanticType.isa?(type)
          attr_fields.merge!('data_type' => AttributeSemanticType.datatype(type).to_s, 'semantic_data_type' => type)
        end
        
        unless attr_fields['data_type']
          fail ParsingError.new('Ill-formed attribute data type (?1)', type)
        end
        attr_fields
      end

      def self.value_asserted(info, attr_fields)
        unless dynamic_default_variable?(info)
          ret = nil
          value = info['default']
          unless value.nil?
            if semantic_data_type = attr_fields['semantic_data_type']
              # TODO: currently converting 'integer' -> integer and 'booelan' -> boolean; this may be unnecesary since the object model stores everything as strings
              ret = AttributeSemanticType.convert_and_raise_error_if_not_valid(semantic_data_type, value, attribute_name: attr_fields['display_name'])
            end
            ret
          else
            nil #just to emphasize want to return nil when no value given
          end
        end
      end
      
      module AttributeSemanticType
        def self.isa?(semantic_type)
          apply('isa?'.to_sym, semantic_type)
        end

        def self.datatype(semantic_type)
          apply(:datatype, semantic_type)
        end

        def self.convert_and_raise_error_if_not_valid(semantic_type, value, opts = {})
          apply(:convert_and_raise_error_if_not_valid, semantic_type, value, opts)
        end

        private

        def self.apply(*method_then_args)
          ::DTK::Attribute::SemanticDatatype.send(*method_then_args)
        end
      end

      module Default
        Datatype = 'string'

        def self.add_defaults_for_nils!(ret, info)
          Fields.each do |field|
            val = info[field.to_s]
            ret[field] = val.nil? ? default(field) : val
          end
          ret
        end

        def self.default(field)
          (Info[field] || {})[:default]
        end

        Info = {
          description: { type: :string,  default: nil },
          dynamic: { type: :boolean, default: false },
          required: { type: :boolean, default: false },
          hidden: { type: :boolean, default: false }
        }
        Fields = Info.keys
      end
    end
  end
end; end; end
