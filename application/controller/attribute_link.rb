
module XYZ
  class Attribute_linkController < Controller
    def list_legal_connections(*parent_uri_array) #TODO stub
      parent_id = nil

      #TODO stub to get project id from project name
      parent_uri = "/" + parent_uri_array.join("/")
      ref,factory_uri =  RestURI.parse_instance_uri(parent_uri)
      parent_model_name = RestURI.parse_factory_uri(factory_uri)
      c = ret_session_context_id()
      Model.create_simple_instance?(parent_uri,c)
      parent_id = ret_id_from_uri(parent_uri)
      ###end of stub

      attribute_links = AttributeLink.get_legal_connections(IDHandle[:c => c, :guid => parent_id])

      tpl = R8Tpl::TemplateR8.new("#{model_name()}/#{default_action_name()}",user_context())
      tpl.assign(:attribute_links,attribute_links)
      tpl.assign(:parent_id,parent_id)
      tpl.assign(:parent_model_name,parent_model_name)
      tpl.assign(:list_start_prev, 0)
      tpl.assign(:list_start_next, 0)
      _model_var = {}
      _model_var[:i18n] = get_model_i18n(model_name().to_s,user_context())
      tpl.assign("_#{model_name().to_s}",_model_var)

      return {:content => tpl.render()}
    end
  end
end
