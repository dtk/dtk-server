module Ramaze::Helper
  module ComponentTemplateHelper
    def ret_component_template_idh(opts={})
      version = (opts[:omit_version] ? nil : ret_version())
      ret_request_param_id_handle(:component_template_name,::DTK::Component::Template,version)
    end

  end
end
