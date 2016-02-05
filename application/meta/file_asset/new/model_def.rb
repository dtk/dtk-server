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
  schema: :file_asset,
  table: :file_asset,
  columns: {
    type: { type: :varchar, size: 25 },
    file_name: { type: :varchar },
    path: { type: :varchar },
    content: { type: :text }
  },
  virtual_columns: {
    implementation_info: {
      type: :json,
      hidden: true,
      remote_dependencies:       [{
         model_name: :implementation,
         convert: true,
         join_type: :left_outer,
         join_cond: { id: :file_asset__implementation_implementation_id },
         cols: [:id, :group_id, :display_name, :type, :repo, :branch]
       }]
    }
  },
  many_to_one: [:component, :implementation]
}