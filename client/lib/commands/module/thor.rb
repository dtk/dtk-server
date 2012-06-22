module DTK::Client
  class ModuleCommand < CommandBaseThor
    def self.pretty_print_cols()
      [:display_name, :id, :version]
    end
    desc "list [library|workspace|remote]","List library, workspace, or remote modules"
    def list(parent)
      case parent
       when "library":
         post rest_url("implementation/list_from_library")
       when "workspace":
         post rest_url("implementation/list_from_workspace")
       when "remote":
         post rest_url("implementation/list_remote")
       else 
         ResponseBadParams.new("module type" => parent)
      end
    end

    desc "import-remote REMOTE-MODULE-NAME [library_id]", "Import remote module into library"
    def import_remote(module_name,library_id=nil)
      post_body = {
       :remote_repo_name => module_name
      }
      post_body.merge!(:library_id => library_id) if library_id
      post rest_url("implementation/import_remote"), post_body
    end

    desc "update-library WORKSPACE-MODULE-ID", "Updates library module with workspace module"
    def update_library(module_id)
      post_body = {
       :implementation_id => module_id
      }
      post rest_url("implementation/update_library"), post_body
    end
  end
end

