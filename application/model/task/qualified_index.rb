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
module DTK; class Task
  module QualifiedIndex
    Field = :qualified_index

    def self.string_form(task)
      convert_to_string_form(task[Field])
    end

    def self.compute!(subtask_indexes, top_task)
      compute_recursive!(subtask_indexes, top_task.id() => {})
    end

    private

    def self.convert_to_string_form(qualified_index)
      qualified_index ? qualified_index.map(&:to_s).join(LabelIndexDelimeter) : ''
    end
    LabelIndexDelimeter = '.'

    # subtask_indexes hash form
    # {subtask_id => {:parent_id => ..., :index => ...}
    def self.compute_recursive!(subtask_indexes, parents)
      ret = {}
      parent_ids = parents.keys
      subtask_indexes.each_pair do |subtask_id, info|
        if parent = parents[info[:parent_id]]
          subtask = subtask_indexes.delete(subtask_id)
          subtask[Field] = (parent[Field] || []) + [subtask[:index]]
          ret.merge!(subtask_id => subtask)
        end
      end
      if ret.empty? || subtask_indexes.empty?
        ret
      else
        ret.merge(compute_recursive!(subtask_indexes, ret))
      end
    end
  end
end; end