module DTK; class Task
  module HierarchicalMixin
    module UpdateMixin
      def update_when_failed_preconditions(_failed_antecedent_tasks)
        update(status: 'preconditions_failed', started_at: ts, ended_at:  Aux.now_time_stamp())
      end

      def update_at_task_start(_opts = {})
        update(status: 'executing', started_at: Aux.now_time_stamp())
      end

      def update_at_task_completion(status, result)
        update(status: status, result: result, ended_at: Aux.now_time_stamp())
      end

      # unlike update_at_task calss above this will be called on top level task
      # TODO: need to clean up to make more sophisticated
      def update_at_task_cancelled(result)
        update_hash = { status: 'cancelled', result: result, ended_at: Aux.now_time_stamp() }
        update(update_hash)
        # find all leaf tasks that are still executing
        executing_leaf_tasks = get_leaf_subtasks().select { |t| t[:status] == 'executing' }
        unless executing_leaf_tasks.empty?
          executing_leaf_tasks.each { |t| t.update(update_hash) }
        end
      end

      RecursiveUpdateLock = Mutex.new
      def update(update_hash, opts = {})
        unless opts[:nested]
          # Top level call; want to lock ful recursive calls
          RecursiveUpdateLock.synchronize do 
            super(update_hash)
            update_next_level(update_hash, opts)
          end
        else
          super(update_hash)
          update_next_level(update_hash, opts)
        end
      end

      private
       
      def update_next_level(update_hash, opts = {})
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
