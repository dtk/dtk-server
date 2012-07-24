module DTK::Client
  class AssemblyCommand < CommandBaseThor
    def self.pretty_print_cols()
      [:display_name, :execution_status, :type, :id, :description, :external_ref]
    end

    desc "export ASSEMBLY-ID", "Exports assembly instance or template"
    def export(assembly_id)
      post_body = {
        :assembly_id => assembly_id
      }
      post rest_url("assembly/export"), post_body
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

    #TODO: put in flag to control detail level
    desc "list [library|target]","List asssemblies in library or target"
    def list(parent="library")
      case parent
        when "library":
          post rest_url("assembly/list_from_library")
        when "target":
          post rest_url("assembly/list_from_target"), "detail_level" => ["attributes"]
       else ResponseBadParams.new("assembly container" => parent)
      end
    end

    desc "list-smoketests ASSEMBLY-ID","List smoketests on asssembly"
    def list_smoketests(assembly_id)
      post_body = {
        :assembly_id => assembly_id
      }
      post rest_url("assembly/list_smoketests"), post_body
    end

    desc "stage ASSEMBLY-TEMPLATE-ID", "Stage library assembly in target"
    method_option "in-target",:aliases => "-t" ,
      :type => :numeric, 
      :banner => "TARGET-ID",
      :desc => "Target (id) to create assembly in" 
    def stage(assembly_template_id)
      post_body = {
        :assembly_template_id => assembly_template_id
      }
      if target_id = options["in-target"]
        post_body.merge!(:target_id => target_id)
      end
      post rest_url("assembly/stage"), post_body
    end

    desc "delete ASSEMBLY-ID", "Delete assembly"
    def delete(assembly_id)
      post_body = {
        :assembly_id => assembly_id
      }
      post rest_url("assembly/delete"), post_body
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

    desc "deploy ASSEMBLY-TEMPLATE-ID", "Deploy assembly from library"
    method_option "in-target",:aliases => "-t" ,
      :type => :numeric, 
      :banner => "TARGET-ID",
      :desc => "Target (id) to create assembly in" 
    def deploy(assembly_template_id)
      post_body = {
        :assembly_template_id => assembly_template_id
      }
      if target_id = options["in-target"]
        post_body.merge!(:target_id => target_id)
      end
      response = post(rest_url("assembly/stage"),post_body)
      return response unless response.ok?
      assembly_id = response.data["assembly_id"]
      converge(assembly_id)
    end
  end
end

