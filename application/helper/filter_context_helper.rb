module Ramaze::Helper
  module FilterContextHelper
    def get_component_filter_constraints?()
      if context = ret_request_params(:context)
        # TODO: stub; code should see if "service/service_name" is in content
        # and if so should see if a component_filter_constraints is associated with service
        # and if not should allow only component templates that are associated with the service
      end
    end

  end
end
