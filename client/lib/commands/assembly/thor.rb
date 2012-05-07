module R8::Client
  class AssemblyCommand < CommandBaseThor
    def self.pretty_print_cols()
      [:display_name, :type,:id, :description, :external_ref]
    end

    desc "converge ASSEMBLY-ID", "Converges assembly instance"
    def converge(assembly_id)
      post_body = {
        :assembly_id => assembly_id
      }
      response = post rest_url("assembly/create_task"), post_body
      return response unless response.ok?
      task_id = response.data["task_id"]
      post rest_url("task/execute"), "task_id" => task_id
    end

    desc "run-smoketests ASSEMBLY-ID", "Run smoketests associated with assembly instance"
    def run_smoketests(assembly_id)
      post_body = {
        :assembly_id => assembly_id
      }
      response = post rest_url("assembly/create_smoketests_task"), post_body
      return response unless response.ok?
      task_id = response.data["task_id"]
      post rest_url("task/execute"), "task_id" => task_id
    end

    desc "list [library|target]","List asssemblies in library or target"
    def list(parent)
      case parent
        when "library":
          post rest_url("assembly/list_from_library")
        when "target":
          post rest_url("assembly/list_from_target")
      end
    end

    desc "stage ASSEMBLY-ID", "Stage library assembly in target"
    method_option "in-target",:aliases => "-t" ,
      :type => :numeric, 
      :banner => "TARGET-ID",
      :desc => "Target (id) to create assembly in" 
    def stage(assembly_id)
      post_body = {
        :assembly_id => assembly_id
      }
      if target_id = options["in-target"]
        post_body.merge!(:target_id => target_id)
      end
      post rest_url("assembly/clone"), post_body
    end

    desc "delete ASSEMBLY-ID", "Delete library assembly"
    def delete(assembly_id)
      post_body = {
        :assembly_id => assembly_id
      }
      post rest_url("assembly/delete_from_library"), post_body
    end

    desc "set ASSEMBLY-ID ATTRIBUTE-PATTERN VALUE", "set target assembly attributes"
    def set(assembly_id,pattern,value)
      post_body = {
        :assembly_id => assembly_id,
        :pattern => pattern,
        :value => value
      }
      post rest_url("assembly/set_attributes"), post_body
    end


    desc "deploy ASSEMBLY-ID", "Deploy assembly from library"
    method_option "in-target",:aliases => "-t" ,
      :type => :numeric, 
      :banner => "TARGET-ID",
      :desc => "Target (id) to create assembly in" 
    def deploy(assembly_id)
      post_body = {
        :assembly_id => assembly_id
      }
      if target_id = options["in-target"]
        post_body.merge!(:target_id => target_id)
      end
      response = post(rest_url("assembly/clone"),post_body)
      return response unless response.ok?
      assembly_id = response.data["assembly_id"]
      converge(assembly_id)
    end
  end
end

