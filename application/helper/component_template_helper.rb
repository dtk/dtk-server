module Ramaze::Helper
  module ComponentTemplateHelper
    def ret_component_template_idh()
      version = ret_request_params(:version)
      ret_request_param_id_handle(:component_template_name,::DTK::Component::Template,version)
    end

  end
end
