#TODO: cleanup; complication is that DSLParsing intersects with dtk common classes
module DTK
  class ErrorUsage 
    class DSLParsing < self
      r8_nested_require('dsl_parsing','legal_values')
      r8_nested_require('dsl_parsing','legal_value')
      r8_nested_require('dsl_parsing','wrong_type')

      def self.raise_error_unless(object,legal_values_input_form=[],&legal_values_block)
        legal_values = LegalValues.reify(legal_values_input_form,&legal_values_block)
        unless legal_values.match?(object)
          raise WrongType.new(object,legal_values,&legal_values_block)
        end
      end
      
      def component_print_form(component_type,context={})
        ret = Component.component_type_print_form(component_type)
        if title = context[:title]
          ret = ComponentTitle.print_form_with_title(ret,title)
        end
          if node_name = context[:node_name]
            ret = "#{node_name}/#{ret}"
          end
        ret
      end
    end
  end
end
