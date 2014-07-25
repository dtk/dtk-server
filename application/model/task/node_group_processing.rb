module DTK
  class Task < Model
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
