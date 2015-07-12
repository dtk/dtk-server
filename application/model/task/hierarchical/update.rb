module DTK; class Task
  module HierarchicalMixin
    module UpdateMixin
      # TODO: after remove from cancel; deprecate
      def update_task_subtask_status(status, result)
        subtasks.each do |subtask|
          if child_subtasks = subtask.subtasks?
            child_subtasks.each do |child_subtask|
              child_subtask.update_at_task_completion(status, result)
            end
          end
          subtask.update_at_task_completion(status, result)
        end
        update_at_task_completion(status, result)
      end
      
      RecursiveUpdateLock = Mutex.new
      def update(update_hash, opts = {})
        unless opts[:nested]
          # Top level call; want to lock ful recursive calls
          RecursiveUpdateLock.synchronize do 
            super(update_hash)
            update_recursive(update_hash, opts)
          end
        else
          super(update_hash)
          update_recursive(update_hash, opts)
        end
      end

      private
       
      def update_recursive(update_hash, opts = {})
        unless opts[:dont_update_parents] || (update_hash.keys & [:status, :started_at, :ended_at]).empty?
          if task_id = update_object!(:task_id)[:task_id]
            update_parents(update_hash.merge(task_id: task_id))
          end
        end
      end

      # updates parent fields that are fn of children (:status,:started_at,:ended_at)
      def update_parents(child_hash)
        parent = id_handle.createIDH(id: child_hash[:task_id]).create_object().update_object!(:status, :started_at, :ended_at, :children_status)
        key = id().to_s.to_sym 
        children_status = (parent[:children_status] || {}).merge!(key => child_hash[:status])
        
        parent_updates = { children_status: children_status }
        # compute parent start time
        unless parent[:started_at] || child_hash[:started_at].nil?
          parent_updates.merge!(started_at: child_hash[:started_at])
        end
        
        # compute new parent status
        subtask_status_array = children_status.values
        parent_status =
          if subtask_status_array.include?('executing') then 'executing'
          elsif subtask_status_array.include?('failed') then 'failed'
          elsif subtask_status_array.include?('cancelled') then 'cancelled'
          elsif not subtask_status_array.find { |s| s != 'succeeded' } then 'succeeded' #all succeeded
          else 'executing' #if reach here must be some created and some finished
          end
        unless parent_status == parent[:status]
          parent_updates.merge!(status: parent_status)
          # compute parent end time which can only change if parent changed to "failed" or "succeeded"
          if ['failed', 'succeeded'].include?(parent_status) && child_hash[:ended_at]
            parent_updates.merge!(ended_at: child_hash[:ended_at])
            end
        end
        
        dont_update_parents = (parent_updates.keys - [:children_status]).empty?
        parent.update(parent_updates, nested: true, dont_update_parents: dont_update_parents)
      end
      
    end
  end
end; end
