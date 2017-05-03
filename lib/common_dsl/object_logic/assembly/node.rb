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
module DTK; module CommonDSL
  module ObjectLogic
    class Assembly
      class Node < ContentInputHash
        require_relative('node/diff')
        require_relative('node/attribute')


        ### For diffs
        # opts can have keys:
        #  :service_instance
        #  :impacted_files
        def diff?(node_parse, qualified_key, opts)
          aggregate_diffs?(qualified_key, opts) do |diff_set|
            diff_set.add_diff_set? Attribute, val(:Attributes), node_parse.val(:Attributes)
            diff_set.add_diff_set? Component, val(:Components), node_parse.val(:Components)
            # TODO: need to add diffs on all subobjects
          end
        end

        # opts can have keys:
        #   :service_instance
        #   :impacted_files
        def self.diff_set(nodes_gen, nodes_parse, qualified_key, opts = {})
          diff_set_from_hashes(nodes_gen, nodes_parse, qualified_key, opts)
        end

        def self.node_has_been_created?(node)
          node.get_admin_op_status != 'pending'
        end

      end
    end
  end
end; end

