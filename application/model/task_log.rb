module XYZ
  class TaskLog < Model
    def self.get_and_update_logs_content(task,assoc_nodes,log_filter)
      ret_info = assoc_nodes.inject({}){|h,n|h.merge(n[:task_id] => {:node => n})}
      log_type = "chef"  #TODO: stub to just get chef run logs
      sp_hash = {
        :cols => [:id,:status,:type,:content, :task_id],
        :filter => [:and, [:oneof, :task_id, assoc_nodes.map{|n|n[:task_id]}],
                    [:eq, :type, "mcollective"]]
      }
      task_log_mh = task.model_handle.createMH(:task_log)
      task_logs = Model.get_objects_from_sp_hash(task_log_mh,sp_hash)

      #associate logs with task_ids and kick of deferred job to get logs for all nodes that dont haev compleet logs in db
      task_logs.each do |task_log|
        task_id = task_log[:task_id]
        #implicit assumption that only one log per task
        ret_info[task_id] = {:log => task_log[:content],:status => task_log[:status]}
      end
      #TODO: compute status from parent task
      incl_assoc_nodes = ret_info.values.reject{|t|t[:status] == "complete"}.map{|info|info[:node]}
      task_pbuilderid_index = incl_assoc_nodes.inject({}){|h,n|h.merge(Node.pbuilderid(n) => n[:task_id])}
      #TODO: stub
      callbacks = {
        :on_msg_received => proc do |msg|
pp [:msg,msg]
          response = CommandAndControl.parse_response__get_logs(task,msg)
          task_id = task_pbuilderid_index[response[:pbuilderid]]
          pp [:received_get_logs,
              {:task_id => task_id,
                :status => response[:status],
                :log_content => response[:log_content] 
              }]
        end
      }
      CommandAndControl.request__get_logs(task,incl_assoc_nodes,callbacks,:log_type => log_type)
      ret_info.values.map{|x|x[:log]}
    end
  end
end
