module Ramaze::Helper
  module TaskHelper
    def cancel_task(top_task_id)
      unless top_task = ::DTK::Task::Hierarchical.get_and_reify(id_handle(top_task_id,:task))
        raise ::DTK::ErrorUsage.new("Task with id '#{top_task_id}' does not exist")
      end
      ::DTK::Workflow.cancel(top_task)
    end

    def most_recent_task_is_executing?(assembly)
      if task = ::DTK::Task.get_top_level_most_recent_task(model_handle(:task), [:eq, :assembly_id, assembly.id()])
        task.has_status?(:executing) && task
      end
    end
  end
end
