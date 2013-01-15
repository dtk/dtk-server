module Ramaze::Helper
  module ModuleHelper
    def import_method_helper(module_class)
      remote_namespace,remote_module_name,version = ::DTK::Repo::Remote::split_qualified_name(ret_non_null_request_params(:remote_module_name))
      local_module_name = ret_request_params(:local_module_name)||remote_module_name 
      remote_repo = ret_remote_repo()
      project = get_default_project()
      remote_params = {
        :repo => remote_repo,
        :namespace => remote_namespace,
        :module_name => remote_module_name,
        :version => version
      }
      local_params = {
        :module_name => local_module_name
      }
      module_class.import(project,remote_params,local_params)
    end

    def ret_remote_repo()
      (ret_request_params(:remote_repo)||::DTK::Repo::Remote.default_remote_repo()).to_sym
    end

    def ret_access_rights()
      if rights = ret_request_params(:access_rights)
        ::DTK::Repo::Remote::AccessRights.convert_from_string_form(rights)
      else
        ::DTK::Repo::Remote::AccessRights::RW
      end
    end

    def ret_library_idh_or_default()
      if ret_request_params(:library_id)
        ret_request_param_id_handle(:library_id,::DTK::Library)
      else
        ::DTK::Library.get_public_library(model_handle(:library)).id_handle()
      end
    end
  end
end
