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
  schema: :project,
  table: :project,
  columns: {
    type: { type: :varchar, size: 25 }
  },                   #TODO: should :implementation,:component be here?
  one_to_many: [:task, :implementation, :component, :node, :component_module, :service_module, :test_module, :node_module, :common_module, :port_link, :node_image, :node_image_attribute],
  virtual_columns: {
    user: {
      type: :json,
      hidden: true,
      remote_dependencies:       [{
         model_name: :user,
         alias: :user,
         convert: true,
         join_type: :inner,
         join_cond: { id: :project__owner_id },
         cols: [:id, :display_name, :username, :c, :user_groups]
       }]
    },
    targets: {
      type: :json,
      hidden: true,
      remote_dependencies:       [{
         model_name: :datacenter,
         alias: :target,
         convert: true,
         join_type: :inner,
         join_cond: { project_id: :project__id },
         cols: [:id, :display_name, :description, :project_id, :iaas_type]
       }]
    },
    target_tree: {
      type: :json,
      hidden: true,
      remote_dependencies:       [{
         model_name: :datacenter,
         alias: :target,
         convert: true,
         join_type: :inner,
         join_cond: { project_id: :project__id },
         cols: Target.common_columns()
       },
                                  {
                                    model_name: :node,
                                    convert: true,
                                    join_type: :left_outer,
                                    join_cond: { datacenter_datacenter_id: :target__id },
                                    cols: Node.common_columns
                                  },
                                  {
                                    model_name: :component,
                                    convert: true,
                                    join_type: :left_outer,
                                    join_cond: { node_node_id: :node__id },
                                    cols: Component.common_columns
                                  }]
    },
    node_group_relations: {
      type: :json,
      hidden: true,
      remote_dependencies:       [{
         model_name: :datacenter,
         alias: :target,
         convert: true,
         join_type: :inner,
         join_cond: { project_id: :project__id },
         cols: [:project_id, :id]
       },
                                  {
                                    model_name: :node_group_relation,
                                    convert: true,
                                    join_type: :inner,
                                    join_cond: { datacenter_datacenter_id: :target__id },
                                    cols: [:node_id, :node_group_id]
                                  }]
    },
    module_tree: {
      type: :json,
      hidden: true,
      remote_dependencies:       [
       {
         model_name: :implementation,
         convert: true,
         join_type: :inner,
         join_cond: { project_project_id: :project__id },
         cols: [:id, :display_name, :type]
       },
       {
         model_name: :component,
         convert: true,
         join_type: :left_outer,
         filter: [:eq, :node_node_id, nil],
         join_cond: { implementation_id: :implementation__id },
         cols: Component.common_columns()
       }]
    },
    implementation_tree: { #TODO: deprecate
      type: :json,
      hidden: true,
      remote_dependencies:       [{
         model_name: :datacenter,
         alias: :target,
         join_type: :inner,
         join_cond: { project_id: :project__id },
         cols: [:id, :display_name, :description, :project_id, :iaas_type]
       },
                                  {
                                    model_name: :node,
                                    join_type: :inner,
                                    join_cond: { datacenter_datacenter_id: :target__id },
                                    cols: [:id, :display_name, :datacenter_datacenter_id]
                                  },
                                  {
                                    model_name: :component,
                                    convert: true,
                                    join_type: :inner,
                                    join_cond: { node_node_id: :node__id },
                                    cols: Component.common_columns()
                                  },
                                  {
                                    model_name: :implementation,
                                    convert: true,
                                    join_type: :inner,
                                    join_cond: { id: :component__implementation_id },
                                    cols: [:id, :display_name, :type]
                                  }]
    }
  }
}