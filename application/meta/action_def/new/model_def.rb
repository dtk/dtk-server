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
  schema: :action,
  table: :def,
  columns: {
    method_name: { type: :varchar, size: 50 },
    content: { type: :json }
  },
  virtual_columns: {
    parameters: {
      type: :json,
      hidden: true,
      remote_dependencies: 
      [
       { model_name: :attribute,
         alias:      :parameter,  
         convert:    true,
         join_type:  :left_outer,
         join_cond:  { action_def_id: :action_def__id },
         cols:       Attribute.common_columns
       }
      ]
    }
  },
  many_to_one: [:component],
  one_to_many: [:attribute]
}