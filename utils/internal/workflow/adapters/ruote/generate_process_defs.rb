require 'json'

module XYZ
  module WorkflowAdapter
    module RuoteGenerateProcessDefs
      @@count = 0
      def compute_process_def(task,guards)
        count = @@count += 1 #TODO: see if we need to keep generating new ones or whether we can (delete) and reuse
        top_task_idh = task.id_handle()
        name = "process-#{count.to_s}"
        context = Context.new(guards,top_task_idh)
        ["define", {"name" => name}, [compute_process_body(task,context)]]
      end

     private
      ####semantic processing
      # TODO: may make decomposition data driven
      def decomposition(task,context)
        action = task[:executable_action]
        if action.kind_of?(Task::Action::PowerOnNode)
          detect_when_ready = participant_executable_action(:power_on_node,task,context, :task_type => "power_on_node", :task_end => true, :task_start => true)
          sequence([detect_when_ready])
        elsif action.kind_of?(Task::Action::InstallAgent)
          main = participant_executable_action(:install_agent,task,context,:task_type => "install_agent",:task_start => true, :task_end => true)
          sequence([main])
        elsif action.kind_of?(Task::Action::ExecuteSmoketest)
          main = participant_executable_action(:execute_smoketest,task,context,:task_type => "execute_smoketest",:task_start => true, :task_end => true)
          sequence([main])
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
          # Sync agent code subtask will be generated only in first inter node stage, or if nil (nil is only when converged from node context)
          sync_agent_code = 
            if task[:executable_action].is_first_inter_node_stage?() and not (R8::Config[:node_agent_git_clone][:mode] == 'off')
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

      def participant_executable_action(name,task,context,opts={})
        raise Error.new("unregistered participant name (#{name})") unless Ruote::ParticipantList.include?(name) 

        nodes = nil
        if decompose_in_ruote =  !ActionsHandlingNodeGroups.include?(name)
          nodes = task[:executable_action].nodes
          decompose_in_ruote = nodes.size > 1 
        end
        if decompose_in_ruote
          decompose_node_group_in_ruote(nodes,name,task,context,opts)
        else
          participant_executable_single_action(name,task,context,opts)
        end
      end
      ActionsHandlingNodeGroups = [:create_node]
      
      def participant_executable_single_action(name,task_input,context,opts={})
        override_node = opts[:override_node]
        task = (opts[:override_node] ? task_input.modify_with_node?(override_node) : task_input)
        top_task_idh = context.top_task_idh
        task_info =  {
          "action" => task[:executable_action],
          "workflow" => self,
          "task" => task,
          "top_task_idh" => top_task_idh
        }

        task_info_opts = Hash.new
        if task_type = opts[:task_type]
          task_info_opts.merge!(:task_type => task_type)
        end
        if override_node
          task_info_opts.merge!(:override_node_id => override_node.id())
        end
        task_id = task.id()
        top_task_id = top_task_idh.get_id()
        Ruote::TaskInfo.set(task_id,top_task_id,task_info,task_info_opts)

        #TODO: figure exactly which of these from opts are needed
        participant_params = opts.merge(
          :task_id => task_id,
          :top_task_id => top_task_id
        )
        if override_node
          participant_param.merge!(:override_node_id => override_node.id())
        end
        participant(name,participant_params)
      end

      # TODO: need to see if big performance improvement if rather than decomposing using ruote
      # from ruote perspective node group is just item
      def decompose_node_group_in_ruote(nodes,name,task,context,opts={})
        concurrence_body = nodes.map{|node|participant_executable_single_action(name,task,new_context,:override_node => node)}
        concurrence(concurrence_body)
      end

      def ret_guards(guard_tasks)
        if guard_tasks.size == 1
          guard(guard_tasks.first)
        else
          concurrence(*guard_tasks.map{|task|guard(task)})
        end
      end

      # formatting fns
      def participant(name,opts={})
        # we set user and session information so that we can reflect that information on newly created threads via Ruote
        opts.merge!(:user_info => { :user => CurrentSession.new.get_user_object.to_json_hash })

        ["participant",to_str_form({"ref" => name}.merge(opts)),[]]
      end

      def guard(task)
        participant = participants_for_tasks[task[:executable_action].class]
        raise Error.new("cannot find participant for task") unless participant
        ["listen",{"to"=>participant.to_s, "upon"=>"reply", "where"=>"${guard_id} == #{task.id().to_s}"},[]]
      end

      def participants_for_tasks()
        @participants_for_tasks ||= {
          # TODO: need condition that signifies detect_created_node_is_ready succeeded
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
        ["concurrence", {"merge_type"=>ConcurrenceMergeType}, subtask_array]
      end
      ConcurrenceMergeType = "ignore" # "stack" || "union" || "isolate" || "stack"

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
          # short circuit if no guards
          return ret if @guards.empty?

          # short circuit; must be multiple peers in order there to be guard tasks
          return ret if @peer_tasks.size < 2

          node_id = action[:node][:id]
          task_type = action.class
          # find guards for this action
          matching_guards = @guards.select do |g|
            guarded = g[:guarded]
            guarded[:task_type] == task_type and guarded[:node][:id] == node_id
          end.map{|g|g[:guard]}
          return nil if matching_guards.empty?
          
          # see if any of the guards are peers
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

