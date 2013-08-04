module DTK; class Task 
  class Template
    class Stage < Hash
      class Factory
        def initialize(action_list,temporal_constraints)
          @action_list = action_list
          @temporal_constraints = temporal_constraints
        end

        def create(stage_action_indexes)
          #first break each state into unordered list per node
          ret = Stage.new()
          stage_action_indexes.each do |index|
            action = @action_list[index]
            (ret[action.node_id] ||= IntraNode::Unordered.new()) << action
          end

          #next break each unordered node into execution blocks
          ret.each_key{|node_id|ret[node_id] = ret[node_id].break_into_execution_blocks()}
          
          #order each execution block
          ret
        end
      end
      
      def print_form()
        ret = Array.new
        return ret if empty?
        element_type = values.first.element_type()
        each do |node_id,node_actions|
          ret << {element_type => node_actions.map{|a|a.print_form()}}
        end
        ret
      end

      module SubClassCommonMixin
        def element_type()
          "IntraNode::#{self.class.to_s.split('::').last}"
        end
      end

      class IntraNode
        #although in an array, order does not make a difference
        class Unordered < Array
          include SubClassCommonMixin
          def break_into_execution_blocks()
            ndx_ret = Hash.new
            each do |action|
              (ndx_ret[execution_block_index(action)] ||= ExecutionBlock::Unordered.new) << action
            end
            ret = ExecutionBlock::Unordered.new
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
      end

      class ExecutionBlock
        class Unordered < Array
          include SubClassCommonMixin
          def print_form()
            map{|a|a.print_form()}
          end
        end
      end
    end
  end
end; end
