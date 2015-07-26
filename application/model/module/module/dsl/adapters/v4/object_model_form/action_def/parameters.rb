module DTK; class ModuleDSL::V4::ObjectModelForm
  class ActionDef
    class Parameters < self
      def self.create?(input_hash, context = {})
        ret = nil
        unless parameters = Constant.matches?(input_hash, :Parameters)
          return ret
        end
        pp [:input_params, parameters]
        ParsingError.raise_error_if_not(parameters, Hash)

        ret = parameters.inject(OutputHash.new) do |h, (attr_name, attr_info)|
          if attr_info.is_a?(Hash)
            opts_attr = { component_type: cmp_type }.merge(opts)
            h.merge(attr_name => attribute_fields(attr_name, attr_info, opts_attr))
          else
            fail ParsingError.new('TODO: need to write this')
#            cmp_name = component_print_form(cmp_type)
#            fail ParsingError.new('Ill-formed attributes section for component (?1): ?2', cmp_name, 'attributes' => parameters)
          end
        end
        pp [:transformed, ret]
        ret
      end
    end
  end
end; end
