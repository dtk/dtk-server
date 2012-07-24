module DTK::Client
  class TargetCommand < CommandBaseThor
    def self.pretty_print_cols()
      [:display_name, :id, :description, :type, :iaas_type]
    end
    desc "list","List targets"
    def list()
      search_hash = SearchHash.new()
      search_hash.cols = pretty_print_cols()
      post rest_url("target/list"), search_hash.post_body_hash()
    end
    desc "create-assembly SERVICE-MODULE-NAME ASSEMBLY-NAME", "Create assembly template from nodes in target" 
    def create_assembly(service_module_name,assembly_name)
      post_body = {
        :service_module_name => service_module_name,
        :assembly_name => assembly_name
      }
      post rest_url("target/create_assembly_template"), post_body
    end
  end
end

