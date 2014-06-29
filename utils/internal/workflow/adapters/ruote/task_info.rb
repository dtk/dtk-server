module DTK; module WorkflowAdapter
  class Ruote
    # This works under the assumption that task_ids are never reused
    class TaskInfo 
      Store = Hash.new
      Lock = Mutex.new
      
#      def self.set(top_task_id, task_id,task_info,task_type=nil)
      def self.set(task_id,task_info,opts={})
        key = task_key(task_id,opts)
        Lock.synchronize{Store[key] = task_info}
      end
      
#      def self.get(task_id,task_type=nil,top_task_id=nil)
      def self.get(task_id,opts={})
        key = task_key(task_id,opts)
        ret = nil
        Lock.synchronize{ret = Store[key]}
        ret
      end
      
#      def self.delete(task_id,task_type=nil,top_task_id=nil)
      def self.delete(ttask_id,opts={})
        key = task_key(task_id,opts)
        Lock.synchronize{Store.delete(key)}
      end
      
      def self.clean(top_task_id)
        Lock.synchronize{ Store.delete_if { |key, value| key.match(/#{top_task_id}.*/) } }
        pp [:write_cleanup,Store.keys]
        # TODO: this needs to clean all keys associated with the task; some handle must be passed in
        # TODO: if run through all the tasks this does not need to be called; so call to cleanup aborted tasks
      end
      
      def self.get_top_task_id(task_id)
        top_key = task_key(task_id)
        top_key.split('-')[0] 
      end
      
      private
      # Amar: altered key format to enable top task cleanup by adding top_task_id on front
#      def self.task_key(task_id,task_type=nil,top_task_id=nil)
      def self.task_key(task_id,opts={})
        task_type = opts[:task_type]
        top_task_id = opts[:top_task_id]
        override_node = opts[:override_node]
        ret_key = task_id.to_s
        ret_key = "#{top_task_id.to_s}-#{ret_key}" if top_task_id
        ret_key = "#{ret_key}-#{task_type}" if task_type
        return ret_key if top_task_id
        
        Store.keys.each do |key|
          if key.match(/.*#{ret_key}/)
            ret_key = key 
            break
          end
        end
        ret_key
      end
    end
  end
end; end
