module DTK
  class Task < Model
    module NodeGroupProcessingMixin
      def node_group_member?()
        (self[:executable_action]||{})[:node_group_member]
      end

      def set_node_group_member_component_actions!(parent)
        ret = self
        [self,parent].each do |task|
          unless task[:executable_action]
            Log.error("Unexpected that (#{task.inspect}) does not have field :executable_action")
            return ret
          end
        end
        unless component_actions = parent[:executable_action][:component_actions]
          Log.error("Unexpected that parent does not have component_actions")
          return ret
        end
        if self[:executable_action][:component_actions]
          Log.error("Unexpected that self has component_actions")
          return ret
        end
        self[:executable_action][:component_actions] = component_actions
        self
      end
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
        nodes = ea.nodes
        return unless nodes.size > 1 
        
        #modify task so that it is a concurrent decomposed task
        task[:temporal_order] = "concurrent"
        ea[:decomposed_node_group] = true
        task[:subtasks] = nodes.map{|node|node_group_member(node,task)}
      end

      def self.node_group_member(node,parent_task)
        executable_action = parent_task[:executable_action].create_node_group_member(node)
        Task.create_stub(parent_task.model_handle(),:executable_action => executable_action)
      end
    end
  end
end
