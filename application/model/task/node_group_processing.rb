module DTK
  class Task < Model
    module NodeGroupProcessingMixin
      def node_group_member?()
        (self[:executable_action]||{})[:node_group_member]
      end

      def set_node_group_member_executable_action!(parent)
        ret = self
        unless ea = self[:executable_action]
          Log.error("Unexpected that self does not have field :executable_action")
          return ret
        end
        unless parent_ea = parent[:executable_action]
          Log.error("Unexpected that parent does not have field :executable_action")
          return ret
        end
        ExecuteActionFieldsToCopy.each{|field|ea[field] = parent_ea[field]}
        ret
      end
      ExecuteActionFieldsToCopy = [:component_actions,:state_change_types,:config_agent_type,:assembly_idh,:inter_node_stage]
    end

    module NodeGroupProcessing
      #replaces node groups with theit elements
      def self.decompose_node_groups!(task)
        decompose!(task)
        task
      end
     private
      def self.decompose!(task)
        case task.basic_type()
          when :executable_action
            decompose_executable_action!(task)
          when :decomposed_node_group
            #no op
          when :sequential
            task.subtasks.map{|st|decompose!(st)}
          when :concurrent
            task.subtasks.map{|st|decompose!(st)}
          else
            Log.error("do not have rules to process task")
        end
      end
      
      def self.decompose_executable_action!(task)
        # noop if this is not a node group that decomposes 
        ea = task[:executable_action]
        return unless ea.node_is_node_group?()
        
        #modify task so that it is a concurrent decomposed task
        task[:temporal_order] = "concurrent"
        ea[:decomposed_node_group] = true
        task[:subtasks] = ea.nodes.map{|node|node_group_member(node,task)}
      end

      def self.node_group_member(node,parent_task)
        executable_action = parent_task[:executable_action].create_node_group_member(node)
        Task.create_stub(parent_task.model_handle(),:executable_action => executable_action)
      end
    end
  end
end
