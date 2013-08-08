module DTK; class Task; class Template
  class Stage 
    class IntraNode
      class Processor
        def initialize(temporal_constraints)
          @intra_node_contraints = temporal_constraints.select{|r|r.intra_node?()}
        end
        def process(intra_node_unordered)
          #first break unordered node into execution blocks          
          #then order each execution block
          #TODO: right now just ordering within each execution block; want to expand to look for global inconsistencies
          exec_blocks = intra_node_unordered.break_into_execution_blocks()
          exec_blocks.order_each_block(@intra_node_contraints)
        end
      end
      #although in an array, order does not make a difference
      class Unordered < Array
        def break_into_execution_blocks()
          ndx_ret = Hash.new
          each do |action|
            (ndx_ret[execution_block_index(action)] ||= ExecutionBlock::Unordered.new) << action
          end
          ret = ExecutionBlocks.new
          ndx_ret.keys.sort.each{|exec_block_index|ret << ndx_ret[exec_block_index]}
          ret
        end
        private
        def execution_block_index(action)
          unless source_type = action.source_type
            raise Error.new("Cannot find source type for action (#{action.inspect})")
          end
          unless ret = ExecBlockOrder[source_type]
            raise Error.new("Not yet implemented, finding execution block order for action with source of type (#{source_type})")
          end
          ret
        end
        ExecBlockOrder = {
          :node_group => 0,
          :node => 0,
          :assembly => 1
        }
      end
      
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
      
      class ExecutionBlock < Array
        def node()
          #all the elements have same node so can just pick first
          first && first[:node]
        end
        def config_agent_type()
          #TODO: for now all  elements have same config_agent_type, so can just pick first
          first && first.config_agent_type()
        end
        def components()
          map{|a|a.hash_subset(*Component::Instance.component_list_fields)}
        end

        def serialization_form()
          map{|a|a.serialization_form()}
        end

        class Unordered < self
          def order(intra_node_contraints,strawman_order=nil)
            #short-cut, no ordering if singleton
            if size < 2
              return Ordered.new(self)
            end
            ret = Ordered.new()
            sorted_action_indexes = intra_node_contraints.ret_sorted_action_indexes(self)
            ndx_action_list = inject(Hash.new){|h,a|h.merge(a.index => a)}
            sorted_action_indexes.each{|index|ret << ndx_action_list[index]}
            ret
          end
        end
        
        class Ordered < self
          def initialize(array=nil)
            super()
            if array
              array.each{|el|self << el}
            end
          end
          
        end
      end
    end
  end
end; end; end
