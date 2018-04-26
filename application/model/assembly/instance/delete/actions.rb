module DTK; class Assembly::Instance
  module DeleteMixin
    module Actions
      def self.delete(service_instance, params, opts = {})
        task_action          = params.last
        service_instance_idh = service_instance.id_handle

        if Task::Template.get_matching_task_template?(service_instance_idh, task_action)
          Task::Template.delete_task_template?(service_instance_idh, task_action)
        else
          fail ErrorUsage, "Action '#{task_action}' does not exist"
        end
      end
    end
  end
end; end