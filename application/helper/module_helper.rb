module Ramaze::Helper
  module ModuleHelper
    def ret_library_idh_or_default()
      library_id = ret_request_params(:library_id)
      library_idh = (library_id && id_handle(library_id,:library)) || ::DTK::Library.get_public_library(model_handle(:library)).id_handle()
      unless library_idh
        raise ::DTK::Error.new("No library specified and no default can be determined")
      end
      library_idh
    end
  end
end
