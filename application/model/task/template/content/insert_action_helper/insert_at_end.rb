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
    class InsertActionHelper
      class InsertAtEnd < self
        def insert_action!(template_content, opts = {})
          template_content.each_internode_stage do |internode_stage, stage_index|
            if action_match = find_earliest_match?(internode_stage, stage_index, :internode, :after)
              # if match here then need to put in stage earlier than matched one
              template_content.splice_in_action!(action_match, :before_internode_stage)
              return template_content
            end
            if action_match = find_earliest_match?(internode_stage, stage_index, :samenode, :after)
              # if match here then need to put in this stage earlier than matched one
              template_content.splice_in_action!(action_match, :before_action_pos)
              return template_content
            end
          end
          action_match = ActionMatch.new(@new_action)
          # TODO: was using
          # template_content.splice_in_action!(action_match,:end_last_internode_stage)
          # but switched to below because it would group together actions in same stage that probably should be seperate stages
          template_content.splice_in_action!(action_match, :add_as_new_last_internode_stage, opts)
          template_content
        end
      end

      def find_earliest_match?(internode_stage, stage_index, inter_or_same, before_or_after)
        ndx_action_indexes = get_ndx_action_indexes(inter_or_same, before_or_after)
        return nil if ndx_action_indexes.empty?()
        action_match = ActionMatch.new(@new_action)
        if internode_stage.find_earliest_match?(action_match, ndx_action_indexes)
          action_match.internode_stage_index = stage_index
          action_match
        end
      end
    end
  end
end; end; end