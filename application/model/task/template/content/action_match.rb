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
  class Content
    class ActionMatch
      def initialize(insert_action = nil)
        @insert_action = insert_action
        # the rest of these attributes are about what matched
        @action = nil
        @in_multinode_stage = nil
        @internode_stage_index = nil
        @execution_block_index = nil
        @action_position = nil
      end
      attr_accessor :insert_action, :action, :internode_stage_index, :execution_block_index, :action_position, :in_multinode_stage
      def node_id
        @action && @action.node_id
      end

      def match_found?
        !@action.nil?
      end

      def is_assembly_wide?
        @action && @action.node && @action.node.is_assembly_wide_node?
      end

    end
  end
end; end; end
