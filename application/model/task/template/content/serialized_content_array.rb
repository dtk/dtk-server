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
  class Task::Template
    class Content
      # wrapper to add processing
      class SerializedContentArray < ::Array
        include Serialization

        def initialize(array)
          super()
          array.each { |a| self << a }
        end
        private :initialize

        def self.normalize(serialized_content, actions, opts = {})
          subtasks             = Constant.matches?(serialized_content, :Subtasks)  || ([] if empty_subtasks?(serialized_content))
          content_params       = Task::ContentParams.get_subtask_content_params!(subtasks) unless subtasks.nil?

          subtask_order_string = Constant.matches?(serialized_content, :SubtaskOrder)
          subtask_order        = subtask_order_string && subtask_order_string.to_sym

          normalized_subtasks =
            if subtasks
              has_multi_stages =  (add_subtask_order_default(subtask_order) == Constant::Sequential)
              has_multi_stages ? subtasks : [{ Field::Subtasks => subtasks }]
            else
              [serialized_content]
            end
          Content.new(new(normalized_subtasks), actions, opts.merge(subtask_order: subtask_order, content_params: content_params))
        end

        private
        
        def self.add_subtask_order_default(subtask_order)
          subtask_order || Constant::Sequential
        end
        
        def self.empty_subtasks?(serialized_content)
          # check if empty workflow by making sure it is not a stage directly not wrapped in subtask
          !Constant.matches?(serialized_content, :Subtasks) and !Constant.matches?(serialized_content, :ComponentsOrActions)
        end

      end
    end
  end
end
