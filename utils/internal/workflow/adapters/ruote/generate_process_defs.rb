module XYZ
  module WorkflowAdapter
    module RuoteGenerateProcessDefs
      @@count = 0
      def compute_process_def(task,guards)
        count = @@count += 1 #TODO: see if we need to keep generating new ones or whether we can (delete) and reuse
        task = task
        top_task_idh = task.id_handle()
        name = "process-#{count.to_s}"
        context = RuoteGenerateProcessDefsContext.create_top(guards,top_task_idh)
        tasks = sequence(compute_process_body(task,context),
                          participant(:end_of_task))
        #for testing
        #tasks = concurrence(tasks,participant(:debug_task))

        ["define", {"name" => name}, [tasks]]
      end
      private

      ####semantic processing
      def decomposition(action,task,context)
        if action.kind_of?(TaskAction::CreateNode)
          main = participant_executable_action(:execute_on_node,task,context)
          post_part_opts = {:task_type => "post", :task_end => true}
          post_part = participant_executable_action(:detect_created_node_is_ready,task,context, post_part_opts)
          sequence(main,post_part)
        elsif action.kind_of?(TaskAction::ConfigNode)
          ##x = context.debug_pp_form()
         ## pp x
        end
      end

      #TODO: make this data driven like .. TaskAction::CreateNode => [:execute_on_node,:detect_created_node_is_ready]

      ####synactic processing
      def compute_process_body(task,context)
        if task[:executable_action]
          compute_process_executable_action(task,context)
        elsif task[:temporal_order] == "sequential"
          compute_process_body_sequential(task.subtasks,context)
        elsif task[:temporal_order] == "concurrent"
          compute_process_body_concurrent(task.subtasks,context)
        else
          Log.error("do not have rules to process task")
        end
      end

      def compute_process_body_sequential(subtasks,context)
        sts = subtasks.map do |t|
          new_context = context.new_sequential_context(t)
          compute_process_body(t,new_context)
        end
        sequence(sts)
      end
      def compute_process_body_concurrent(subtasks,context)
        new_context = context.new_concurrent_context(subtasks)
        concurrence(subtasks.map{|t|compute_process_body(t,new_context)})
      end

      def compute_process_executable_action(task,context)
        action = task[:executable_action]
        decomposition(action,task,context) || participant_executable_action(:execute_on_node,task,context, :task_end => true)
      end
      def participant_executable_action(name,task,context,args={})
        raise Error.new("unregistered participant name (#{name})") unless Ruote::ParticipantList.include?(name) 
        executable_action = task[:executable_action]
        task_info = {
          "action" => executable_action,
          "workflow" => self,
          "top_task_idh" => context.top_task_idh
        }
        task_id = task.id()
        Ruote::TaskInfo.set(task_id,task_info,args[:task_type])
        participant(name,{:task_id => task_id,:top_task_idh => context.top_task_idh}.merge(args))
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
      class RuoteGenerateProcessDefsContext < HashObject
        def self.create_top(guards,top_task_idh)
          new(:guards => guards, :top_task_idh => top_task_idh)
        end
        def top_task_idh()
          self[:top_task_idh]
        end
        def new_concurrent_context(task_list)
          if self[:peer_tasks]
            Log.error("nested concurrent under concurrent context not implemented")
          end
          self.class.new(self).merge(:peer_tasks => task_list) 
        end
        def new_sequential_context(task)
          if self[:peer_tasks]
            Log.error("nested sequential under concurrent context not implemented")
          end
          self
        end
        
        def debug_pp_form()
          if peer_tasks = self[:peer_tasks]
            peer_tasks = peer_tasks.map do |t|
              {
                :task_id => t[:task_id],
                :node => (t[:executable_action]||{})[:node],
                :type => t[:executable_action] && t[:executable_action].class
              }
            end
          end
          {
            :top_task_idh => self[:top_task_idh],
            :guards => self[:guards],
            :peer_tasks => peer_tasks
          }
        end
      end
    end
end

