module DTK; class Task
  module HierarchicalMixin
    module UpdateMixin
      def update_when_failed_preconditions(_failed_antecedent_tasks)
        update(status: status(:preconditions_failed), started_at: ts, ended_at:  now_time_stamp())
      end

      def update_at_task_start(_opts = {})
        update(status: status(:executing), started_at: now_time_stamp())
      end

      def update_at_task_completion(status, result)
        update(status: status, result: result, ended_at: now_time_stamp())
      end

      # unlike update_at_task class above this will be called on top level task
      def update_at_task_cancelled(result)
        update_hash = { status: status(:cancelled), result: result, ended_at: now_time_stamp() }
        update(update_hash)
        # find all leaf tasks that are still executing
        executing_leaf_tasks = get_leaf_subtasks().select { |t| t.has_status?(:executing) }
        unless executing_leaf_tasks.empty?
          executing_leaf_tasks.each { |t| t.update(update_hash) }
        end
      end

      RecursiveUpdateLock = Mutex.new
      # when called at top level (:nested is nil) then put the operations in amutex
      def update(update_hash, opts = {})
        to_execute = proc do 
          unless donot_update?(update_hash)
            super(update_hash)
            update_next_level(update_hash, opts)
          end
        end
        unless opts[:nested]
          RecursiveUpdateLock.synchronize do 
            to_execute.call()
          end
        else
          to_execute.call()
        end
      end

      private

      def status(type)
        Status::Type.send(type.to_sym)
      end

      def now_time_stamp
        Aux.now_time_stamp
      end

      def donot_update?(update_hash)
        # if cancel is set in db then dont change values
        status = update_hash[:status]
        status and status.to_sym != Status::Type.cancelled and  has_status?(:cancelled)
      end
       
      def update_next_level(update_hash, opts = {})
        unless opts[:dont_update_parents] || (update_hash.keys & [:status, :started_at, :ended_at]).empty?
          if task_id = update_object!(:task_id)[:task_id]
            update_parents(update_hash.merge(task_id: task_id))
          end
        end
      end

      # updates parent fields that are fn of children (:status,:started_at,:ended_at)
      def update_parents(child_hash)
        parent = get_parent(child_hash)

        # compute updates for parent
        #
        parent_updates = Hash.new

        # compute parent start time
        unless parent[:started_at] || child_hash[:started_at].nil?
          parent_updates.merge!(started_at: child_hash[:started_at])
        end
        # compute parent children_status
        children_status = updated_children_status?(parent, child_hash)
        unless children_status.empty?
          parent_updates.merge!(children_status: children_status)

          # compute parent status
          new_parent_status = new_parent_status(children_status)
          unless new_parent_status == parent.get_field?(:status)
            parent_updates.merge!(status: new_parent_status)
            # compute parent end time which can only change if there is a completion status
            if has_task_completion_status?(new_parent_status) && child_hash[:ended_at]
              parent_updates.merge!(ended_at: child_hash[:ended_at])
            end
          end
        end
        
        unless parent_updates.empty?
          dont_update_parents = (parent_updates.keys - [:children_status]).empty?
          parent.update(parent_updates, nested: true, dont_update_parents: dont_update_parents)
        end
      end
      
      def get_parent(child_hash)
        id_handle.createIDH(id: child_hash[:task_id]).create_object().update_object!(:status, :started_at, :ended_at, :children_status)
      end
      
      def updated_children_status?(parent_task, child_hash)
        ret = parent_task[:children_status] || {}
        key = id().to_s.to_sym 
        unless ret.has_key?(key) and ret[key] == child_hash[:status]
          ret = ret.merge(key => child_hash[:status])
        end
        ret
      end

      def new_parent_status(children_status)
        status_array = children_status.values
        if includes_status?(status_array, :cancelled) 
          # if one cancelled then parent cancelled
          Status::Type.cancelled
        elsif includes_status?(status_array, :failed)
          # if one failed then parent cancelled 
          Status::Type.failed
        elsif includes_status?(status_array, :preconditions_failed)
          # if one failed then parent cancelled 
          Status::Type.failed
        elsif not status_array.find { |s| s != Status::Type.succeeded } 
          # if all succeeded then parent succeeded
          Status::Type.succeeded #all succeeded
        else 
          #if reach here must be some in progress
          Status::Type.executing 
        end
      end
      
      def has_task_completion_status?(status)
        includes_status?(CompletionStatusArray, status)
      end
      CompletionStatusArray = [:succeeded, :failed, :cancelled, :preconditions_failed]

      def includes_status?(status_array, status)
        Status::Type.includes_status?(status_array, status)
      end

    end
  end
end; end

