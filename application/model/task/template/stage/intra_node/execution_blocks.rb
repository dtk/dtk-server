module DTK; class Task; class Template
  class Stage; class IntraNode
    class ExecutionBlocks < Array
      def add_subtask!(parent_task,internode_stage_index,assembly_idh=nil)
        executable_action = Task::Action::ConfigNode.create_from_execution_blocks(self,assembly_idh)
        executable_action.set_inter_node_stage!(internode_stage_index)
        sub_task = Task.create_stub(parent_task.model_handle(),:executable_action => executable_action)
        parent_task.add_subtask(sub_task)
        executable_action
      end
      
      def order_each_block(intra_node_contraints)
        ret = self.class.new()
        each do |unordered_exec_block|
          ret << unordered_exec_block.order(intra_node_contraints)
        end
        ret
      end
      
      def intra_node_stages()
        ret = Array.new
        return ret if empty?()
        if find{|eb|!eb.kind_of?(ExecutionBlock::Ordered)}
          raise Error.new("The method ExecutionBlocks#intra_node_stages can only be caleld if all its elements are orederd")
        end
        map{|eb|eb.components.map{|cmp|cmp[:id]}}
      end
      
      def node()
        #all the elements have same node so can just pick first
        first && first.node()
      end
      
      def node_name()
        (node()||{})[:display_name]
      end
      
      def config_agent_type()
        #TODO: for now all  elements have same config_agent_type, so can just pick first
        first && first.config_agent_type()
      end
      def components()
        ret = Array.new
        each{|exec_block|ret += exec_block.components()}
        ret
      end
      
      def serialization_form()
        map{|a|a.serialization_form()}
      end
    end
  end; end
end; end; end
