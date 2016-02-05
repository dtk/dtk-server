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
  schema: :node,
  table: :group_relation,
  columns: {
    node_id: {
      type: :bigint,
      foreign_key_rel_type: :node,
      on_delete: :cascade,
      on_update: :cascade
    },
    node_group_id: {
      type: :bigint,
      foreign_key_rel_type: :node,
      on_delete: :cascade,
      on_update: :cascade
    }
  },
  many_to_one: [:datacenter, :library],
  virtual_columns: {
    service_node_group: {
      type: :json,
      hidden: true,
      remote_dependencies: [{
          model_name: :node,
          alias: :service_node_group,
          convert: true,
          join_type: :inner,
          join_cond: { id: :node_group_relation__node_group_id },
          cols: [:id, :group_id, :display_name, :type]
       }]
    },
    target_ref: {
      type: :json,
      hidden: true,
      remote_dependencies: [{
          model_name: :node,
          alias: :target_ref,
          convert: true,
          join_type: :inner,
          join_cond: { id: :node_group_relation__node_id },
          cols: [:id, :group_id, :display_name, :type, :external_ref]
       }]
    },
    target_refs_with_links: {
      type: :json,
      hidden: true,
      remote_dependencies: [{
          model_name: :node,
          alias: :target_ref,
          convert: true,
          join_type: :inner,
          join_cond: { id: :node_group_relation__node_id },
          cols: [:id, :group_id, :display_name, :type, :external_ref]
       },
                            {
                               model_name: :node_group_relation,
                               alias: :link,
                               join_type: :inner,
                               convert: true,
                               join_cond: { node_id: :node_group_relation__node_id },
                               cols: [:id, :group_id, :node_id, :node_group_id]
                            }]
    },
    node_member_assembly: {
      type: :json,
      hidden: true,
      remote_dependencies: [{
          model_name: :node,
          alias: :node_group,
          convert: true,
          join_type: :inner,
          join_cond: { id: :node_group_relation__node_group_id },
          cols: [:id, :group_id, :display_name, :type, :assembly_id]
        },
                            {
                              model_name: :component,
                              alias: :assembly,
                              join_type: :inner,
                              convert: true,
                              join_cond: { id: :node_group__assembly_id },
                              cols: [:id, :group_id, :display_name]
                            }]
    }
  }
}