module XYZ
  class TaskController < Controller
    def get_logs(task_id=nil)
      #task_id is nil means get most recent task
      unless task_id
        model_handle = ModelHandle.new(ret_session_context_id(),model_name)

        tasks = Task.get_top_level_tasks(model_handle).sort{|a,b| b[:updated_at] <=> a[:updated_at]}
        task = tasks.first
      else
        raise Error.new("not implemented yet get_logs with task id given")
      end
      assoc_nodes = task.get_associated_nodes()
      pp assoc_nodes
      logs = CommandAndControl.get_logs(task,assoc_nodes)
      pp logs
      {:content => {}}
    end
  end
end
