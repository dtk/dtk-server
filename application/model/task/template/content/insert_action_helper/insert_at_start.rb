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
module DTK
  class Task::Template::Content
    class InsertActionHelper
      class InsertAtStart < self
        def insert_action?(template_content)
          unless template_content.includes_action?(@new_action)
            action_match = ActionMatch.new(@new_action)
            action_match.internode_stage_index = 1
            template_content.splice_in_action!(action_match, :before_internode_stage)
            template_content
          end
        end
        
      end
    end
  end
end
