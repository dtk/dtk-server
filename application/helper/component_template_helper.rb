module Ramaze::Helper
  module ComponentTemplateHelper
    def ret_component_template_idh(opts={})
      version = nil
      unless opts[:omit_version]
        if version = ret_request_params(:version)
        raise_error_if_version_illegal_format(version)
        end
      end
      ret_request_param_id_handle(:component_template_name,::DTK::Component::Template,version)
    end

  end
end
