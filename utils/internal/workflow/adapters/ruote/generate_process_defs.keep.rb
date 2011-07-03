module XYZ
  module WorkflowAdapter
    module RuoteGenerateProcessDefs
      @@count = 0
      def compute_process_def(task,guards)
        count = @@count += 1 #TODO: see if we need to keep generating new ones or whether we can (delete) and reuse
        task = task
        top_task_idh = task.id_handle()
        name = "process-#{count.to_s}"
        tasks = sequence(compute_process_body(task,top_task_idh),
                          participant(:end_of_task))
        #for testing
        #tasks = concurrence(tasks,participant(:debug_task))

        ["define", {"name" => name}, [tasks]]
      end
      private

      ####semantic processing
      def decomposition(action,task,top_task_idh)
        if action.kind_of?(TaskAction::CreateNode)
          main = participant_executable_action(:execute_on_node,task,top_task_idh)
          post_part_opts = {:task_type => "post", :task_end => true}
          post_part = participant_executable_action(:detect_created_node_is_ready,task,top_task_idh, post_part_opts)
          sequence(main,post_part)
        end
      end
      #TODO: make this data driven like .. TaskAction::CreateNode => [:execute_on_node,:detect_created_node_is_ready]

      ####synactic processing
      def compute_process_body(task,top_task_idh)
        if task[:executable_action]
          compute_process_executable_action(task,top_task_idh)
        elsif task[:temporal_order] == "sequential"
          compute_process_body_sequential(task.subtasks,top_task_idh)
        elsif task[:temporal_order] == "concurrent"
          compute_process_body_concurrent(task.subtasks,top_task_idh)
        else
          Log.error("do not have rules to process task")
        end
      end
      def compute_process_body_sequential(subtasks,top_task_idh)
        sequence(subtasks.map{|t|compute_process_body(t,top_task_idh)})
      end
      def compute_process_body_concurrent(subtasks,top_task_idh)
        concurrence(subtasks.map{|t|compute_process_body(t,top_task_idh)})
      end

      def compute_process_executable_action(task,top_task_idh)
        action = task[:executable_action]
        decomposition(action,task,top_task_idh) || participant_executable_action(:execute_on_node,task,top_task_idh, :task_end => true)
      end
      def participant_executable_action(name,task,top_task_idh,args={})
        raise Error.new("unregistered participant name (#{name})") unless Ruote::ParticipantList.include?(name) 
        executable_action = task[:executable_action]
        task_info = {
          "action" => executable_action,
          "workflow" => self,
          "top_task_idh" => top_task_idh
        }
        task_id = task.id()
        Ruote::TaskInfo.set(task_id,task_info,args[:task_type])
        participant(name,{:task_id => task_id,:top_task_idh => top_task_idh}.merge(args))
      end

      #formatting fns
      def participant(name,opts={})
        ["participant",to_str_form({"ref" => name}.merge(opts)),[]]
      end

      def sequence(*subtask_array_x)
        subtask_array = subtask_array_x.size == 1 ? subtask_array_x.first : subtask_array_x
        ["sequence", {}, subtask_array]
      end

      def concurrence(*subtask_array_x)
        subtask_array = subtask_array_x.size == 1 ? subtask_array_x.first : subtask_array_x
        ["concurrence", {"merge_type"=>ConcurrenceType}, subtask_array]
      end
      ConcurrenceType = "stack" # "union" || "isolate" || "stack"

      def to_str_form(hash)
        hash.inject({}) do |h,(k,v)|
          h.merge((k.kind_of?(Symbol) ? k.to_s : k) => (v.kind_of?(Symbol) ? v.to_s : v))
        end
      end

    end
  end
end
