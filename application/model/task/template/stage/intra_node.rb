module DTK; class Task; class Template
  class Stage 
    class IntraNode
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
          #TODO: stub
          0
        end
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
