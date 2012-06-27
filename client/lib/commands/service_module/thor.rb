module DTK::Client
  class ServiceModuleCommand < CommandBaseThor
    def self.pretty_print_cols()
      [:display_name, :id, :version]
    end
    desc "list [library|remote]","List library, workspace,or remote service modules"
    def list(parent)
      case parent
       when "library":
         post rest_url("service_module/list_from_library")
       when "remote":
         post rest_url("service_module/list_remote")
       else 
         ResponseBadParams.new("module type" => parent)
      end
    end

    desc "list-assemblies SERVICE-MODULE-ID","List assemblies in teh service module"
    def list_assemblies(service_module_id)
      post_body = {
       :service_module_id => service_module_id
      }
      post rest_url("service_module/list_assemblies"), post_body
    end

    desc "create MODULE-NAME [library_id]", "Create an empty service module in library"
    def create(module_name,library_id=nil)
      post_body = {
       :module_name => module_name
      }
      post_body.merge!(:library_id => library_id) if library_id
      post rest_url("service_module/create"), post_body
    end
  end
end

