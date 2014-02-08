module DTK
 class ComponentDSL
    class ParsingError < ModuleDSL::ParsingError
      r8_nested_require('parsing_error','ref_component_templates')
      r8_nested_require('parsing_error','link_def')
      r8_nested_require('parsing_error','dependency')
      r8_nested_require('parsing_error','missing_key')

      def initialize(msg='',*args)
        parsing_error,@params = msg_pp_form_and_params(msg,*args)
        super("Component dsl parsing error: #{parsing_error}",:caller_info => true)
      end


    end
  end
end


