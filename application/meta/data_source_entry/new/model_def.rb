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
  schema: :data_source,
  table: :entry,
  columns: {
    ds_name: { type: :varchar, size: 25 },
    update_policy: { type: :varchar, size: 25 },
    ancestor_id: {
      type: :bigint,
      foreign_key_rel_type: :data_source_entry,
      on_delete: :set_null,
      on_update: :set_null
    },
    source_obj_type: { type: :varchar, size: 25 },
    polling_policy: { type: :json },
    ds_is_golden_store: { type: :boolean, default: true },
    polling_task_id: {
      type: :bigint,
      foreign_key_rel_type: :task,
      on_delete: :set_null,
      on_update: :set_null
    },
    filter: { type: :json },
    placement_location: { type: :json },
    obj_type: { type: :varchar, size: 25 } },
  virtual_columns: {},
  many_to_one: [:data_source, :data_source_entry],
  one_to_many: [:data_source_entry]
}