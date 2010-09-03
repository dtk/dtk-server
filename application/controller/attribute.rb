module XYZ
  class AttributeController < Controller
    def component_display(parsed_query_string=nil)
      where_clause = parsed_query_string || ret_parsed_query_string()
      opts = {:field_set => field_set()}
      model_list = get_objects(model_name().to_sym,where_clause,opts)

      #TODO: should we be using default action name
      action_name = :list
      tpl = R8Tpl::TemplateR8.new("#{model_name()}/#{action_name}",user_context())
      _model_var = {}
      _model_var[:i18n] = get_model_i18n(model_name().to_s,user_context())
      tpl.assign("_#{model_name().to_s}",_model_var)

      tpl.assign("#{model_name()}_list",model_list)
      tpl.assign(:list_start_prev, 0)
      tpl.assign(:list_start_next, 0)

      return {:content => tpl.render()}
    end
  end
end
