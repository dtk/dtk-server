
module XYZ
  class Attribute_linkController < Controller
    def list_legal_connections(project_name,parsed_query_string=nil) #stub for parent_id/model_name
      opts = {:depth => :deep}
      parent_id = nil
      #TODO stub to get project id from project name
      parent_uri = "/project/#{project_name}"

      c = ret_session_context_id()
      Model.create_simple_instance?(parent_uri,c)
      parent_id = ret_id_from_uri(parent_uri)
      ###end of stub

      where_clause = {:parent_id => parent_id}
      model_list = get_objects(:component,where_clause,opts)
pp  model_list
      tpl = R8Tpl::TemplateR8.new("#{model_name()}/#{default_action_name()}",user_context())
      tpl.assign("#{model_name().to_s}_list",model_list)
      #TODO: needed to below back in so template did not barf
      tpl.assign(:list_start_prev, 0)
      tpl.assign(:list_start_next, 0)
 # }
      _model_var = {}
      _model_var[:i18n] = get_model_i18n(model_name().to_s,user_context())
      tpl.assign("_#{model_name().to_s}",_model_var)

      return {:content => tpl.render()}
    end
  end
end
