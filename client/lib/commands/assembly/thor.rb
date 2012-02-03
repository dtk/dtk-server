module R8::Client
  class AssemblyCommand < CommandBaseThor
    def self.pretty_print_cols()
      [:display_name, :type,:id, :description, :external_ref]
    end
    desc "list","List asssemblies in library"
    def list()
      post rest_url("assembly/list_from_library")
    end

    desc "execute ASSEMBLY-ID", "Excute assembly from library"
    def execute(assembly_id)
      post_body = {
        :assembly_id => assembly_id
      }
      post rest_url("assembly/clone"), post_body
    end
  end
end

