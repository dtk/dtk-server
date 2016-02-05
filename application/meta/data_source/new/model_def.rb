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
  table: :data_source,
  columns: {
    ds_name: { type: :varchar, size: 25 },
    source_handle: { type: :json },
    ancestor_id: {
      type: :bigint,
      foreign_key_rel_type: :data_source,
      on_delete: :set_null,
      on_update: :set_null
    },
    last_collection_timestamp: { type: :timestamp } },
  virtual_columns: {},
  many_to_one: [:library, :datacenter],
  one_to_many: [:data_source_entry]
}