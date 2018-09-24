module DTK; class Assembly::Instance
  module AddByPath
    module Actions
      def self.add(service_instance, params, opts = {})
        response = nil
        task_action_name     = params[:name]
        service_instance_idh = service_instance.id_handle
        service_instance_branch = service_instance.get_service_instance_branch
        content = YAML.load(params[:content])

        if Task::Template.get_matching_task_template?(service_instance_idh, task_action_name)
          fail ErrorUsage, "Action '#{task_action_name}' already exist exist"
        else
          Task::Template.create_from_serialized_content(service_instance_idh, content, task_action_name)
          CommonDSL::Generate::ServiceInstance.generate_dsl_and_push!(service_instance, service_instance_branch)
          response = CommonModule::ServiceInstance::RepoInfo.new(service_instance_branch)
        end

        response
      end
    end
  end
end; end