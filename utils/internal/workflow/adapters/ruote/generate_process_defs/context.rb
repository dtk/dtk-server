module DTK; module WorkflowAdapter; module RuoteGenerateProcessDefs
  module ContextMixin
    def ret_guards(guard_tasks)
      if guard_tasks.size == 1
        guard(guard_tasks.first)
      else
        concurrence(*guard_tasks.map{|task|guard(task)})
      end
    end
    
    def guard(task)
      participant = participants_for_tasks[task[:executable_action].class]
      raise Error.new("cannot find participant for task") unless participant
      ["listen",{"to"=>participant.to_s, "upon"=>"reply", "where"=>"${guard_id} == #{task.id()}"},[]]
    end
    
    class Context
      def self.create(guards,top_task_idh,peer_tasks=nil)
        if guards and not guards.empty?
          Guards.new(guards,top_task_idh,peer_tasks)
        else
          NoGuards.new(top_task_idh)
        end
      end

      attr_reader :top_task_idh   
      def initialize(top_task_idh)     
        @top_task_idh = top_task_idh
      end
      
      class NoGuards < self
        def initialize(top_task_idh)
          super(top_task_idh)
        end

        def get_guard_tasks(_action)
          nil
        end

        def new_concurrent_context(_task_list)
          self
        end

        def new_sequential_context(_task)
          self
        end
      end

      class Guards < self
        def initialize(guards,top_task_idh,peer_tasks=nil)
          super(top_task_idh)
          @guards = guards||[]
          @peer_tasks = peer_tasks||[]
        end

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
            guarded[:task_type] == task_type && guarded[:node][:id] == node_id
          end.map{|g|g[:guard]}
          return nil if matching_guards.empty?
          
          # see if any of the guards are peers
          ndx_ret = {}
          @peer_tasks.each do |t|
            task_id = t.id()
            next if ndx_ret[task_id]
            if ea = t[:executable_action]
              task_node_id = ea[:node][:id]
              task_type = ea.class
              if matching_guards.find{|g|g[:task_type] == task_type && g[:node][:id] == task_node_id}
                ndx_ret[task_id] = t
              end
            end
          end
          ndx_ret.empty? ? nil : ndx_ret.values
        end

        def new_concurrent_context(task_list)
          unless @peer_tasks.empty?
            raise ErrorUsage.new("nested concurrent under concurrent context not implemented")
          end
          self.class.new(@guards,@top_task_idh,task_list)
        end

        def new_sequential_context(_task)
          unless @peer_tasks.empty?
            raise ErrorUsage.new("sequential under concurrent context not implemented")
          end
          self
        end
      end
    end
  end
end; end; end

