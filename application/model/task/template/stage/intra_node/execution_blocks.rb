module DTK; class Task; class Template
  class Stage; class IntraNode
    class ExecutionBlocks < Array
      include Serialization
      def add_subtask!(parent_task,internode_stage_index,assembly_idh=nil)
        executable_action = Task::Action::ConfigNode.create_from_execution_blocks(self,assembly_idh)
        executable_action.set_inter_node_stage!(internode_stage_index)
        sub_task = Task.create_stub(parent_task.model_handle(),:executable_action => executable_action)
        parent_task.add_subtask(sub_task)
        executable_action
      end

      def splice_in_at_beginning!(execution_blocks)
        pp [:fooooo,serialization_form(),execution_blocks.serialization_form()]
        self
      end

      def serialization_form(opts={})
        opts_x = {:no_node_name_prefix => true}.merge(opts)
        execution_blocks =  map{|eb|eb.serialization_form(opts_x)}.compact
        return nil if execution_blocks.empty?()

        ret = OrderedHash.new()
        if node_name = node_name()
          ret[:node] = node_name
        end
        if execution_blocks.size == 1
          #if single execution block then we remove this level of nesting
          ret.merge(execution_blocks.first)
        else          
          ret.merge(Field::ExecutionBlocks =>  execution_blocks)
        end
      end
      def self.parse_and_reify(serialized_node_actions,node_name,action_list)
        #normalize to take into account it may be single execution block
        normalized_content = serialized_node_actions[Field::ExecutionBlocks]||[serialized_node_actions]
        ret = new()
        normalized_content.each{|serialized_eb|ret << ExecutionBlock::Ordered.parse_and_reify(serialized_eb,node_name,action_list)}
        ret
      end

      def order_each_block(intra_node_constraints)
        ret = self.class.new()
        each do |unordered_exec_block|
          ret << unordered_exec_block.order(intra_node_constraints)
        end
        ret
      end
      
      def intra_node_stages()
        ret = Array.new
        return ret if empty?()
        if find{|eb|!eb.kind_of?(ExecutionBlock::Ordered)}
          raise Error.new("The method ExecutionBlocks#intra_node_stages can only be called if all its elements are ordered")
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
      
    end
  end; end
end; end; end
