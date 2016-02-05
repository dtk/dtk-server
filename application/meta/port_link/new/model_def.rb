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
  schema: :port,
  table: :link,
  columns: {
    input_id: {
      type: :bigint,
      foreign_key_rel_type: :port,
      on_delete: :cascade,
      on_update: :cascade
    },
    output_id: {
      type: :bigint,
      foreign_key_rel_type: :port,
      on_delete: :cascade,
      on_update: :cascade
    },
    # TODO: assembly id may be redundant with component; if so remove
    assembly_id: {
      type: :bigint,
      foreign_key_rel_type: :component,
      on_delete: :cascade,
      on_update: :cascade
    },
    # these two used when parent is service_add_on
    required: { type: :boolean },
    temporal_order: { type: :varchar, size: 20 }, #output_first | #input_first
    output_is_local: { type: :boolean }
  },
  virtual_columns: {
    ports: {
      type: :json,
      hidden: true,
      remote_dependencies:       [{ model_name: :port,
                                    alias: :input_port,
                                    convert: true,
                                    join_type: :inner,
                                    join_cond: { id: :port_link__input_id },
                                    cols: Port.common_columns()
       },
                                  {
                                    model_name: :port,
                                    alias: :output_port,
                                    convert: true,
                                    join_type: :inner,
                                    join_cond: { id: :port_link__output_id },
                                    cols: Port.common_columns()
                                  }]
    },
    augmented_ports: {
      type: :json,
      hidden: true,
      remote_dependencies:       [{ model_name: :port,
                                    alias: :input_port,
                                    convert: true,
                                    join_type: :inner,
                                    join_cond: { id: :port_link__input_id },
                                    cols: Port.common_columns()
       },
                                  {
                                    model_name: :component,
                                    alias: :input_component,
                                    convert: true,
                                    join_type: :left_outer,
                                    join_cond: { id: :input_port__component_id },
                                    cols: [:id, :display_name, :group_id, :node_node_id, :component_type, :extended_base, :implementation_id]
                                  },
                                  {
                                    model_name: :port,
                                    alias: :output_port,
                                    convert: true,
                                    join_type: :inner,
                                    join_cond: { id: :port_link__output_id },
                                    cols: Port.common_columns()
                                  },
                                  {
                                    model_name: :component,
                                    alias: :output_component,
                                    convert: true,
                                    join_type: :left_outer,
                                    join_cond: { id: :output_port__component_id },
                                    cols: [:id, :display_name, :group_id, :node_node_id, :component_type, :extended_base, :implementation_id]
                                  }]
    }
  },
  many_to_one: [:project, :datacenter, :component, :service_add_on, :library] #MOD_RESTRUCT: remove library
}