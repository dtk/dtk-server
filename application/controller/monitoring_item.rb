module XYZ
  class Monitoring_itemController < Controller
    def list_for_component_display(parsed_query_string=nil)
      component_or_node_display(parsed_query_string)
    end
    def node_display(parsed_query_string=nil)
      component_or_node_display(parsed_query_string)
    end
   private
    #helper fn
    def component_or_node_display(parsed_query_string=nil)
      where_clause = parsed_query_string || ret_parsed_query_string()
      parent_id = where_clause.delete(:parent_id)
      opts = Hash.new
      opts.merge!(:parent_id => parent_id) if parent_id
      model_list = get_objects(model_name().to_sym,where_clause,opts)

      #TODO: should we be using default action name
      action_name = :list
      tpl = R8Tpl::TemplateR8.new("#{model_name()}/#{action_name}",user_context())
      _model_var = {}
      _model_var[:i18n] = get_model_i18n(model_name().to_s,user_context())

      set_template_defaults_for_list!(tpl)
      tpl.assign("_#{model_name().to_s}",_model_var)
      tpl.assign("#{model_name()}_list",model_list)

      return {:content => tpl.render()}
    end
  end
end
