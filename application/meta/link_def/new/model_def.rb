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
  schema: :link_def,
  table: :link_def,
  columns: {
    local_or_remote: { type: :varchar, size: 10 },
    link_type: { type: :varchar, size: 50 },
    required: { type: :boolean },
    dangling: { type: :boolean, default: false },
    has_external_link: { type: :boolean },
    has_internal_link: { type: :boolean }
  },
  virtual_columns: {
    link_def_link: {
      type: :json,
      hidden: true,
      remote_dependencies:       [{
         model_name: :link_def_link,
         convert: true,
         join_type: :left_outer,
         join_cond: { link_def_id: :link_def__id },
         cols: LinkDef::Link.common_columns()
       }]
    }
  },
  many_to_one: [:component],
  one_to_many: [:link_def_link]
}