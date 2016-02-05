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
{
  schema: :task,
  table: :log,
  columns: {
    status: { type: :varchar, size: 20, default: 'empty' }, # = "in_progress" | "complete"
    type: { type: :varchar, size: 20 }, # "chef" || "puppet"
    content: { type: :json },
    position: { type: :integer }
  },
  many_to_one: [:task],
  virtual_columns: {
    parent_task: {
      type: :json,
      hidden: true,
      remote_dependencies:       [{
         model_name: :task,
         convert: true,
         join_type: :inner,
         join_cond: { id: :task_id },
         cols: [:id, :display_name]
       }]
    }
  }
}