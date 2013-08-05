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
        end
      end
      #although in an array, order does not make a difference
      class Unordered < Array
        def break_into_execution_blocks()
          ndx_ret = Hash.new
          each do |action|
            (ndx_ret[execution_block_index(action)] ||= ExecutionBlock::Unordered.new) << action
          end
          ret = ExecutionBlocks .new
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
      end
      
      class ExecutionBlock < Array
        class Unordered < self
          def serialization_form()
            map{|a|a.serialization_form()}
          end
        end
        
        class Ordered < self
        end
      end
    end
  end
end; end; end
