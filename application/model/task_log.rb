module XYZ
  class TaskLog < Model
    def self.get_and_update_logs_content(task,assoc_nodes,log_filter)
      sp_hash = {
        :cols => [:id,:status,:type,:content, :task_id],
        :filter => [:oneof, :task_id, assoc_nodes.map{|n|n[:task_id]}]
      }
      task_log_mh = task.model_handle.createMH(:task_log)
      task_logs = Model.get_objects_from_sp_hash(task_log_mh,sp_hash)
      #TODO: stub
      CommandAndControl.get_logs(task,assoc_nodes)
    end
  end
end
