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
module DTK; 
  class Task::Template::Stage
    class InterNode
      class NestedSubtask < self
        def initialize(serialized_content)
          super(serialized_content[:name])
          set_optional_fields!(serialized_content)
          # subtasks get dynamically set by parse_and_reify!
          @subtasks = []
        end
        private :initialize

        # opts can have keys:
        #  :just_parse (Boolean)
        def self.parse_and_reify(serialized_content, action_list, opts = {})
          new(serialized_content).parse_and_reify!(serialized_content, action_list, just_parse: opts[:just_parse])
        end
        
        def parse_and_reify!(serialized_content, action_list, opts = {})
          unless subtasks = serialized_content[Field::Subtasks]
            fail Error, "Unexpected that serialized_content[Field::Subtasks] is nil"
          end
          subtasks.each do |subtask|
            reified_subtask = 
              if subtask[Field::Subtasks]
                NestedSubtask.parse_and_reify(subtask, action_list, opts)
              else
                InterNode.parse_and_ret_normalized_content([subtask], serialized_content, action_list, opts)
              end
            @subtasks << reified_subtask
          end
          self
        end
        
        def serialization_form(opts = {})
          optional_fields_for_serialization_form.merge(Field::Subtasks => @subtasks.map { |subtask| subtask.serialization_form(opts) })
        end

        # TODO: DTK-2680: Aldin
        # Put this in to flatten subtasks when nested subtaskl but this is creating error
         def add_subtasks!(parent_task, internode_stage_index, assembly_idh = nil)
           ret = []
           if flatten?
            @subtasks.each do |subtask|
               ret += subtask.add_subtasks!(parent_task, internode_stage_index, assembly_idh)
             end
           else
             @subtasks.flatten.each do |subtask|
               ret += subtask.add_subtasks!(parent_task, internode_stage_index, assembly_idh)
             end
             # fail Error, "Non flatten nested subtasks not treated"
           end
           ret
         end

         # TODO: DTK-2680: Aldin; we need to check if this is written right
         def delete_action!(action_match)
           delete_elements = []
           @subtasks.each_with_index do |subtask, i| 
             if :empty == subtask.delete_action!(action_match) 
               delete_elements << i
             end
           end
           # Need to rerverse order since when delete it shifts order if from beginning
           delete_elements.reverse.each { |i| @subtasks.delete_at(i) }
           :empty if @subtasks.empty?
         end
        
        def find_earliest_match?(action_match, ndx_action_indexes)
          ret = nil
          @subtasks.each do |subtask| 
            if ret = subtask.find_earliest_match?(action_match, ndx_action_indexes)
              return ret
            end
          end
          ret
        end
        
        # opts can have keys:
        #  :just_parse
        def add_to_template_content!(template_content, _serialized_content, _opts = {})
          template_content << self unless @subtasks.empty?
        end

        private

        OPTIONAL_FIELDS = [Field::SubtaskOrder, Field::Import, Field::Flatten]
        def set_optional_fields!(serialized_content)
          @optional_fields = OPTIONAL_FIELDS.inject({}) do |h, k| 
            v = serialized_content[k]
            v.nil? ? h : h.merge(k => v)
          end
        end

        def optional_fields_for_serialization_form
          @optional_fields
        end

        def flatten?
          @optional_fields[Field::Flatten]
        end

      end
    end
  end
end
