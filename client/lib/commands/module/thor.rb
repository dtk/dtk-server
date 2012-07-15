#TODO: may be consistent on whether component module id or componnet module name used as params
module DTK::Client
  class ModuleCommand < CommandBaseThor
    def self.pretty_print_cols()
      [:display_name, :id, :version]
    end
    desc "list [library|remote]","List library or remote component modules"
    def list(parent="library")
      case parent
       when "library":
         post rest_url("component_module/list_from_library")
       when "remote":
         post rest_url("component_module/list_remote")
       else 
         ResponseBadParams.new("module type" => parent)
      end
    end

    desc "import REMOTE-MODULE-NAME[,REMOTE-MODULE-NAME2..] [library_id]", "Import remote module(s) into library"
    def import(module_name_x,library_id=nil)
      module_names = module_name_x.split(",")
      if module_names.size > 1
        return module_names.map{|module_name|import(module_name,library_id)}
      end
      module_name = module_names.first
      post_body = {
       :remote_module_name => module_name
      }
      post_body.merge!(:library_id => library_id) if library_id
      post rest_url("component_module/import"), post_body
    end

    desc "update-library COMPONENT-MODULE-ID", "Updates library module with workspace module"
    def update_library(component_module_id)
      post_body = {
       :component_module_id => component_module_id
      }
      post rest_url("component_module/update_library"), post_body
    end

    desc "revert-workspace COMPONENT-MODULE-ID", "Revert workspace (discarding changes) to library version"
    def revert_workspace(component_module_id)
      post_body = {
       :component_module_id => component_module_id
      }
      post rest_url("component_module/revert_workspace"), post_body
    end

    desc "delete COMPONENT-MODULE-ID", "Delete component module and all items contained in it"
    def delete(component_module_id)
      post_body = {
       :component_module_id => component_module_id
      }
      post rest_url("component_module/delete"), post_body
    end
  end
end

