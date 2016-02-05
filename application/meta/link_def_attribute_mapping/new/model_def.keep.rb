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
# TODO: Marked for removal [Haris]
{
  schema: :link_def,
  table: :attribute_mapping,
  columns: {
    output_attribute_id: {
      type: :bigint,
      foreign_key_rel_type: :attribute,
      on_delete: :cascade,
      on_update: :cascade
    },
    output_component_name: { type: :varchar, size: 50 },
    output_attribute_name: { type: :varchar, size: 50 },
    output_path: { type: :varchar, size: 50 },
    output_contant: { type: :varchar }, #if this is non null that means that input set to a constant value
    input_attribute_id: {
      type: :bigint,
      foreign_key_rel_type: :attribute,
      on_delete: :cascade,
      on_update: :cascade
    },
    input_component_name: { type: :varchar, size: 50 },
    input_attribute_name: { type: :varchar, size: 50 },
    input_path: { type: :varchar, size: 50 },
    function: { type: :varchar, default: 'equal' }
  },
  many_to_one: [:link_def_possible_link]
}