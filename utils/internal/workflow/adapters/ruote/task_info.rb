module DTK; module WorkflowAdapter
  class Ruote
    # This works under the assumption that task_ids are never reused
    class TaskInfo 
      Store = Hash.new
      Lock = Mutex.new
      
      def self.set(task_id,top_task_id,task_info,opts={})
        key = task_key(task_id,top_task_id,opts)
        Lock.synchronize{Store[key] = task_info}
      end
      
      def self.get(workitem)
        key = get_from_workitem(workitem)
        ret = nil
        Lock.synchronize{ret = Store[key]}
        unless ret
          Log.error("cannot find match for key: #{key}")
        end
        ret
      end
      
      def self.delete(workitem)
        key = get_from_workitem(workitem)
        Lock.synchronize{Store.delete(key)}
      end
      
      def self.clean(top_task_id)
        Lock.synchronize{ Store.delete_if { |key, value| key.match(Regexp.new("^#{top_task_id.to_s}#{TopTaskDelim}")) }}
        pp [:write_cleanup,Store.keys]
        # TODO: this needs to clean all keys associated with the task; some handle must be passed in
        # TODO: if run through all the tasks this does not need to be called; so call to cleanup aborted tasks
      end

      TopTaskDelim = '-'

     private
      def self.get_from_workitem(workitem)
        params = workitem.params
        task_id = params["task_id"]
        top_task_id = params["top_task_id"]
        opts = Hash.new
        if task_type = params["task_type"]
          opts.merge!(:task_type => task_type)
        end
        if override_node_id = params["override_node_id"]
          opts.merge!(:override_node_id => override_node_id)
        end
        task_key(task_id,top_task_id,opts)
      end

      # opts can have keys
      #  :task_type
      #  ::override_node_id 
      def self.task_key(task_id,top_task_id,opts={})
        ret_key = "#{top_task_id.to_s}#{TopTaskDelim}#{task_id.to_s}"
        if task_type = opts[:task_type]
          ret_key <<  "--#{task_type}"
        end
        if override_node_id = opts[:override_node_id]
          ret_key << "---#{override_node_id}"
        end
        ret_key
      end
    end
  end
end; end
