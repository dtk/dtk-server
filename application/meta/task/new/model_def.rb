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
  table: :task,
  columns: {
    status: { type: :varchar, size: 30, default: 'created' }, # = "created" | "executing" | "succeeded" | "failed" | "preconditions_failed" | "canceled"
    started_at: { type: :timestamp },
    ended_at: { type: :timestamp },
    result: { type: :json }, # gets serialized version of TaskAction::Result
    action_on_failure: { type: :varchar, default: 'abort' },
    commit_message: { type: :varchar }, #only on top level task
    temporal_order: { type: :varchar, size: 20 }, # = "sequential" | "concurrent"
    position: { type: :integer, default: 1 },
    executable_action_type: { type: :varchar },
    executable_action: { type: :json }, #gets serialized version of TaskAction::Action
    breakpoint: { type: :boolean },
    assembly_id: { #points to assembly when assembly task
      type: :bigint,
      foreign_key_rel_type: :component,
      on_delete: :set_null,
      on_update: :set_null
    },
    node_id: { #points to node or node group when node-centric task
      type: :bigint,
      foreign_key_rel_type: :node,
      on_delete: :set_null,
      on_update: :set_null
    },
    target_id: { #points to target when target task
      type: :bigint,
      foreign_key_rel_type: :datacenter,
      on_delete: :set_null,
      on_update: :set_null
    },
    children_status: { type: :json }, #caching children status; hash of form {child1_id => status1, ..}
    # TODO: the value of this in relation to attributes in executable action is confusing; these have the updated attribute values
    bound_input_attrs: { type: :json },
    bound_output_attrs: { type: :json } #these are the dynamic attributes with values at time of task completion
  },
  many_to_one: [:project, :task],
  one_to_many: [:task, :task_log, :task_event, :task_error]
}
