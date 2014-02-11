module DTK
 class ComponentDSL
    class ParsingError < ErrorUsage::Parsing
      r8_nested_require('parsing_error','ref_component_templates')
      r8_nested_require('parsing_error','link_def')
      r8_nested_require('parsing_error','dependency')
      r8_nested_require('parsing_error','missing_key')

      def initialize(msg='',*args_x)
        args = Params.add_opts(args_x,:error_prefix => ErrorPrefix,:caller_info => true)
        super(msg,*args)
      end
      ErrorPrefix = 'Component dsl parsing error'
    end
  end
end


