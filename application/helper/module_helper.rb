module Ramaze::Helper
  module ModuleHelper
    def ret_library_idh_or_default()
      if ret_request_params(:library_id)
        ret_request_param_id_handle(:library_id,::DTK::Library)
      else
        ::DTK::Library.get_public_library(model_handle(:library)).id_handle()
      end
    end
  end
end
