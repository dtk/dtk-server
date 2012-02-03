module R8::Client
  class AssemblyCommand < CommandBaseThor
    def self.pretty_print_cols()
      [:display_name, :type,:id, :description, :external_ref]
    end
    desc "list","List asssemblies in library"
    def list()
      post rest_url("assembly/list_from_library")
    end

    desc "clone ASSEMBLY-ID", "Clone assembly from library to target"
    method_option "in-target",:aliases => "-t" ,
      :type => :numeric, 
      :banner => "TARGET-ID",
      :desc => "Target (id) to create assembly in" 
    def clone(assembly_id)
      post_body = {
        :assembly_id => assembly_id
      }
      if target_id = options["in-target"]
        post_body.merge!(:target_id => target_id)
      end
      post rest_url("assembly/clone"), post_body
    end

    desc "execute ASSEMBLY-ID", "Excute assembly from library"
    method_option "in-target",:aliases => "-t" ,
      :type => :numeric, 
      :banner => "TARGET-ID",
      :desc => "Target (id) to create assembly in" 
    def execute(assembly_id)
      post_body = {
        :assembly_id => assembly_id
      }
      if target_id = options["in-target"]
        post_body.merge!(:target_id => target_id)
      end
      response = post(rest_url("assembly/clone"),post_body)
      return response unless response.ok?
      
      #TODO: if options["in-target"] then below must take this value
      response = post(rest_url("task/create_task_commit_changes"))
      return response unless response.ok?

      task_id = response.data["task_id"]
      post rest_url("task/execute"), "task_id" => task_id
    end
  end
end

