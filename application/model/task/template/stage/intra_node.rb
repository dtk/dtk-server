#
# Copyright (C) 2010-2016 dtk contributors
#
# This file is part of the dtk project.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
module DTK; class Task; class Template
  class Stage
    class IntraNode
      r8_nested_require('intra_node', 'execution_block')
      r8_nested_require('intra_node', 'execution_blocks')
      class Processor
        def initialize(temporal_constraints)
          @intra_node_contraints = temporal_constraints.select(&:intra_node?)
        end

        def process(intra_node_unordered)
          # first break unordered node into execution blocks
          # then order each execution block
          # TODO: right now just ordering within each execution block; want to expand to look for global inconsistencies
          exec_blocks = intra_node_unordered.break_into_execution_blocks()
          exec_blocks.order_each_block(@intra_node_contraints)
        end
      end
      # although in an array, order does not make a difference
      class Unordered < Array
        def break_into_execution_blocks
          ndx_ret = {}
          each do |action|
            (ndx_ret[execution_block_index(action)] ||= ExecutionBlock::Unordered.new) << action
          end
          ret = ExecutionBlocks.new
          ndx_ret.keys.sort.each { |exec_block_index| ret << ndx_ret[exec_block_index] }
          ret
        end

        private

        def execution_block_index(action)
          unless source_type = action.source_type
            fail Error.new("Cannot find source type for action (#{action.inspect})")
          end
          unless ret = ExecBlockOrder[source_type]
            fail Error.new("Not yet implemented, finding execution block order for action with source of type (#{source_type})")
          end
          ret
        end
        ExecBlockOrder = {
          node_group: 0,
          node: 0,
          assembly: 1
        }
      end
    end
  end
end; end; end