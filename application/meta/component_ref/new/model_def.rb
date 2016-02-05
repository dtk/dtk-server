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
  schema: :component,
  table: :ref,
  columns: {
    component_type: { type: :varchar, size: 50 },
    version: { type: :varchar, size: 100 },
    has_override_version: { type: :boolean, default: false }, #whether this has an insstance assigned to this instance, which oevrrides any global version setting of assembly this is in
    # must point to :component_template_id or have :component_type and version set
    component_template_id: {
      type: :bigint,
      foreign_key_rel_type: :component,
      on_delete: :set_null,
      on_update: :set_null
    },
    template_id_synched: { type: :boolean, default: false } #indicates whether :component_template_id is set and currently synced
    # which wil allow cheaper search when tarce to and from component refs and compoennt templtaes
  },
  virtual_columns: {
    node_and_template_info: {
      type: :json,
      hidden: true,
      remote_dependencies:       [{
         model_name: :node,
         convert: true,
         join_type: :inner,
         join_cond: { id: :component_ref__node_node_id },
         cols: [:id, :group_id, :display_name, :assembly_id]
       },
                                  {
                                     model_name: :component,
                                     convert: true,
                                     alias: :component_template,
                                     join_type: :left_outer,
                                     join_cond: { id: :component_ref__component_template_id },
                                     cols: [:id, :group_id, :display_name, :component_type, :only_one_per_node, :version, :module_branch_id]
                                   }]
    },

    # MOD_RESTRUCT: check if still applicable
    component_templates: {
      type: :json,
      hidden: true,
      remote_dependencies:       [{
         model_name: :component,
         convert: true,
         alias: :component_template,
         join_type: :inner,
         join_cond: { id: :component_ref__component_template_id },
         cols: [:id, :group_id, :display_name, :component_type, :only_one_per_node]
       }]
    }
  },
  many_to_one: [:node],
  one_to_many: [:attribute_override]
}