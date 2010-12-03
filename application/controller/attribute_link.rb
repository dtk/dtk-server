
module XYZ
  class Attribute_linkController < Controller
    helper :ports
    #TODO: right now just for testing
    def list_legal_connections(*parent_uri_array) #TODO stub
      parent_id = nil
      parent_uri = (parent_uri_array.empty? ? "/datacenter/dc1" : "/" + parent_uri_array.join("/"))
      parent_id = ret_id_from_uri(parent_uri)
      parent_model_name = "datacenter"
      #TODO: stubbed for just links under datacenters
      augmented_attributes = get_external_ports_under_datacenter(parent_id)
      #TODO stub to go from ports to form needed by view
      port_list = Array.new
      augmented_attributes.each do |row|
        port_list <<
          {
          :id => row[:id],
          :node_name => row[:node][:display_name],
          :component_name => row[:component][:display_name],
          :port_name => row[:display_name]
        }
      end
      tpl = R8Tpl::TemplateR8.new("#{model_name()}/#{default_action_name()}",user_context())
      tpl.assign(:port_list,port_list)
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
