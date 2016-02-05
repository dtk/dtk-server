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
  schema: :module,
  table: :module_ref,
  columns: {
    module_name: { type: :varchar, size: 50 },
    module_type: { type: :varchar, size: 25 },
    version_info: { type: :json },
    namespace_info: { type: :json },
    external_ref: { type: :json }
  },
  virtual_columns: {
    is_dependency_to_component_modules: {
      type: :json,
      hidden: true,
      remote_dependencies:
      [
        {
          model_name: :module_branch,
          convert: true,
          join_type: :inner,
          join_cond: { id: :module_ref__branch_id },
          cols: [:id, :display_name, :branch, :version, :component_id]
         },
        {
          model_name: :component_module,
          convert: true,
          join_type: :inner,
          join_cond: { id: :module_branch__component_id },
          cols: [:id, :display_name, :namespace_id]
        },
        {
          model_name: :namespace,
          convert: true,
          join_type: :inner,
          join_cond: { id: :component_module__namespace_id },
          cols: [:id, :display_name]
        }
      ]
    },
    is_dependency_to_service_modules: {
      type: :json,
      hidden: true,
      remote_dependencies:
      [
        {
          model_name: :module_branch,
          convert: true,
          join_type: :inner,
          join_cond: { id: :module_ref__branch_id },
          cols: [:id, :display_name, :branch, :version, :service_id]
         },
        {
          model_name: :service_module,
          convert: true,
          join_type: :inner,
          join_cond: { id: :module_branch__service_id },
          cols: [:id, :display_name, :namespace_id]
        },
        {
          model_name: :namespace,
          convert: true,
          join_type: :inner,
          join_cond: { id: :service_module__namespace_id },
          cols: [:id, :display_name]
        }
      ]
    }
  },
  many_to_one: [:module_branch]
}
         # join_cond: { node_node_id: :node__id, component_type: :nested_component__component_type },