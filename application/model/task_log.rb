module XYZ
  class TaskLog < Model
    def self.get_and_update_logs_content(task,assoc_nodes,_log_filter)
      ret_info = assoc_nodes.inject({}){|h,n|h.merge(n[:task_id] => {node: n})}
      sp_hash = {
        cols: [:id,:status,:type,:content, :task_id],
        filter: [:oneof, :task_id, assoc_nodes.map{|n|n[:task_id]}]
      }
      task_log_mh = task.model_handle.createMH(:task_log)
      task_logs = Model.get_objects_from_sp_hash(task_log_mh,sp_hash)

      # associate logs with task_ids and kick of deferred job to get logs for all nodes that dont haev compleet logs in db
      task_logs.each do |task_log|
        task_id = task_log[:task_id]
        # implicit assumption that only one log per task
        ret_info[task_id].merge!(task_log.slice({content: :log},:status,:type))
      end
      incl_assoc_nodes = ret_info.values.reject{|t|t[:status] == "complete"}.map{|info|info[:node]}
      unless incl_assoc_nodes.empty?
        # initiate defer task to get logs
        task_pbuilderid_index = incl_assoc_nodes.inject({}){|h,n|h.merge(Node.pbuilderid(n) => n[:task_id])}
        config_agent_types = assoc_nodes.inject({}){|h,n|h.merge(n[:task_id] => n[:config_agent_type])}
        callbacks = {
          on_msg_received: proc do |msg|
            response = CommandAndControl.parse_response__get_logs(task,msg)
            if response[:status] == :ok
              task_id = task_pbuilderid_index[response[:pbuilderid]]
              task_idh = task.model_handle.createIDH(id: task_id)
              config_agent_type = config_agent_types[task_id]
              TaskLog.create_or_update(task_idh,config_agent_type.to_s,response[:log_content])
            else
              Log.error("error response for request to get log")
              # TODO: put some subset of this in error msg
              pp msg
            end
          end
        }
        CommandAndControl.request__get_logs(task,incl_assoc_nodes,callbacks,log_type: :config_agent)
      end
      ret_info.values.inject({}){|h,log_info|h.merge(log_info[:node][:id] => log_info)}
    end

    def self.create_or_update(task_idh,log_type,log_content)
      task_id = task_idh.get_id()
      status = ParseLog.log_complete?(log_type,log_content) ? "complete" : "in_progress"

      # create if needed
      sp_hash = {
        cols: [:id],
        filter: [:and, [:eq, :task_id, task_id],
                 [:eq, :type, log_type.to_s]]
      }
      task_log_mh = task_idh.createMH(:task_log)
      existing = Model.get_objects_from_sp_hash(task_log_mh,sp_hash).first
      row = {
        task_id: task_id,
        status: status,
        type: log_type.to_s,
        content: log_content
      }
      if existing
        id = existing[:id]
        ret = task_log_mh.createIDH(id: id)
        row.merge!(id: id)
        Model.update_from_rows(task_log_mh,[row])
      else
        row.merge!(ref: log_type.to_s)
        ret = Model.create_from_row(task_log_mh,row,convert: true)
      end
      ret
    end
  end
end
