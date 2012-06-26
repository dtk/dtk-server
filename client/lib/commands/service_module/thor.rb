module DTK::Client
  class ServiceModuleCommand < CommandBaseThor
    def self.pretty_print_cols()
      [:display_name, :id, :version]
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

