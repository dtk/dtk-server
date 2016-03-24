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
  schema: :library,
  table: :library,
  columns: {
    ancestor_id: {
      type: :bigint,
      foreign_key_rel_type: :library,
      on_delete: :set_null,
      on_update: :set_null
    }
  },
  virtual_columns: {},
  many_to_one: [],
  one_to_many:   [
   :component,
   :node,
   :node_binding_ruleset,
   :node_group_relation,
   :attribute_link,
   :port_link, #MOD_RESTRUCT: may remove
   :region,
   :data_source,
   :constraints,
   :component_relation,
   :implementation,
   :component_module, #MOD_RESTRUCT: may remove
   :service_module, #MOD_RESTRUCT: may remove
   :test_module, #MOD_RESTRUCT: may remove
   :node_module #MOD_RESTRUCT: may remove
  ]
}
