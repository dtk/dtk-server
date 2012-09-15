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

    def get_default_project()
      projects = ::DTK::Project.get_all(model_handle(:project))
      if projects.empty?
        raise DTK::Error.new("Cannot find any projects")
      elsif projects.size > 1
        raise DTK::Error.new("Not implemented yet: case when multiple projects")
      end
      projects.first
    end
  end
end
