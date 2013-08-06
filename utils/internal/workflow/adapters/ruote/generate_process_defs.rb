module XYZ
  module WorkflowAdapter
    module RuoteGenerateProcessDefs
      @@count = 0
      def compute_process_def(task,guards)
        count = @@count += 1 #TODO: see if we need to keep generating new ones or whether we can (delete) and reuse
        top_task_idh = task.id_handle()
        name = "process-#{count.to_s}"
        context = Context.new(guards,top_task_idh)
        tasks = sequence(compute_process_body(task,context),
                          participant(:end_of_task))
        #for testing
        #tasks = concurrence(tasks,participant(:debug_task))
        ["define", {"name" => name}, [tasks]]
      end
      private

      ####semantic processing
      #TODO: may make decomposition data driven
      def decomposition(task,context)
        action = task[:executable_action]
        if action.kind_of?(Task::Action::PowerOnNode)
          detect_when_ready = participant_executable_action(:power_on_node,task,context, :task_type => "power_on_node", :task_end => true, :task_start => true)
          sequence([detect_when_ready])
        elsif action.kind_of?(Task::Action::CreateNode)
          main = participant_executable_action(:create_node,task,context,:task_start => true)
          post_part = participant_executable_action(:detect_created_node_is_ready,task,context, :task_type => "post", :task_end => true)
          sequence(main,post_part)
        elsif action.kind_of?(Task::Action::ConfigNode)
          guards = nil
          if guard_tasks = context.get_guard_tasks(action)
            guards = ret_guards(guard_tasks)
          end
          authorize_action = participant_executable_action(:authorize_node,task,context,:task_type => "authorize_node", :task_start => true)
          main = participant_executable_action(:execute_on_node,task,context,:task_type => "config_node",:task_end => true)
          # Amar: sync agent code subtask will be generated only in first inter node stage, or if nil (nil is only when converged from node context)
          sync_agent_code = 
            if task[:executable_action].is_first_inter_node_stage?()
              sync_agent_code = participant_executable_action(:sync_agent_code,task,context,:task_type => "sync_agent_code")
            end
          sequence_tasks = [guards,authorize_action,sync_agent_code,main].compact
          sequence(*sequence_tasks)
        end
      end

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
        decomposition(task,context) || participant_executable_action(:execute_on_node,task,context, :task_start => true, :task_end => true)
      end
      def participant_executable_action(name,task,context,args={})
        raise Error.new("unregistered participant name (#{name})") unless Ruote::ParticipantList.include?(name) 
        executable_action = task[:executable_action]
        task_info = {
          "action" => executable_action,
          "workflow" => self,
          "task" => task,
          "top_task_idh" => context.top_task_idh
        }
        task_id = task.id()
        Ruote::TaskInfo.set(context.top_task_idh.get_id(), task_id,task_info,args[:task_type])
        participant(name,{:task_id => task_id,:top_task_idh => context.top_task_idh}.merge(args))
      end

      def ret_guards(guard_tasks)
        if guard_tasks.size == 1
          guard(guard_tasks.first)
        else
          concurrence(*guard_tasks.map{|task|guard(task)})
        end
      end

      #formatting fns
      def participant(name,opts={})
        ["participant",to_str_form({"ref" => name}.merge(opts)),[]]
      end

      def guard(task)
        participant = participants_for_tasks[task[:executable_action].class]
        raise Error.new("cannot find participant for task") unless participant
        ["listen",{"to"=>participant.to_s, "upon"=>"reply", "where"=>"${guard_id} == #{task.id().to_s}"},[]]
      end

      def participants_for_tasks()
        @participants_for_tasks ||= {
          #TODO: need condition that signifies detect_created_node_is_ready succeeded
          Task::Action::CreateNode => :detect_created_node_is_ready,
          Task::Action::ConfigNode => :execute_on_node
        }
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

      class Context 
        def initialize(guards,top_task_idh,peer_tasks=nil)
          @guards = guards||[]
          @top_task_idh = top_task_idh
          @peer_tasks = peer_tasks||[]
        end

        attr_reader :top_task_idh

        def get_guard_tasks(action)
          ret = nil
          # If 'STAGES' temporal mode set, don't generate workflow with guards
          return ret unless  Workflow.guards_mode?

          #short cuircuit; must be multiple peers in order there to be guard tasks
          return ret if @peer_tasks.size < 2
          node_id = action[:node][:id]
          task_type = action.class
          #find guards for this action
          matching_guards = @guards.select do |g|
            guarded = g[:guarded]
            guarded[:task_type] == task_type and guarded[:node][:id] == node_id
          end.map{|g|g[:guard]}
          return nil if matching_guards.empty?
          
          #see if any of the guards are peers
          ndx_ret = Hash.new
          @peer_tasks.each do |t|
            task_id = t.id()
            next if ndx_ret[task_id]
            if ea = t[:executable_action]
              task_node_id = ea[:node][:id]
              task_type = ea.class
              if matching_guards.find{|g|g[:task_type] == task_type and g[:node][:id] == task_node_id}
                ndx_ret[task_id] = t
              end
            end
          end
          ndx_ret.empty? ? nil : ndx_ret.values
        end

        def new_concurrent_context(task_list)
          unless @peer_tasks.empty?
            Log.error("nested concurrent under concurrent context not implemented")
          end
          self.class.new(@guards,@top_task_idh,task_list)
        end
        def new_sequential_context(task)
          unless @peer_tasks.empty?
            Log.error("nested sequential under concurrent context not implemented")
          end
          self
        end
      end
    end
  end
end

