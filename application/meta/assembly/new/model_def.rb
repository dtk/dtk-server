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
segment_assembly_template = {
  model_name: :component,
  convert: true,
  alias: :assembly_template,
  join_type: :left_outer,
  join_cond: { id: :component__ancestor_id },
  cols: [:id, :group_id, :display_name, :component_type, :version, :implementation_id]
}
lambda__segment_module_branch =
  lambda do|module_branch_cols|
  {
    model_name: :module_branch,
    convert: true,
    join_type: :inner,
    join_cond: { id: :component__module_branch_id },
    cols: module_branch_cols
  }
end

lambda__segment_node =
  lambda do|node_cols|
  {
    model_name: :node,
    convert: true,
    join_type: :inner,
    join_cond: { assembly_id: q(:component, :id) },
    cols: node_cols
  }
end
segment_component_ref = {
  model_name: :component_ref,
  convert: true,
  join_type: :inner,
  join_cond: { node_node_id: :node__id },
  cols: ComponentRef.common_cols()
}
lambda__segment_component_template =
  lambda do|join_type|
  {
    model_name: :component,
    convert: true,
    alias: :component_template,
    join_type: join_type,
    join_cond: { id: q(:component_ref, :component_template_id) },
    cols: [:id, :display_name, :component_type, :version, :basic_type, :description]
  }
end
lambda__segments_nodes_and_components =
  lambda do|node_cols, cmp_cols|
    [
     {
       model_name: :component,
       convert: true,
       alias: :nested_component,
       join_type: :left_outer,
       join_cond: { assembly_id: q(:component, :id) },
       cols: (cmp_cols + [:node_node_id]).uniq
     },
     {
       model_name: :node,
       convert: true,
       join_type: :left_outer,
       join_cond: { id: q(:nested_component, :node_node_id) },
       cols: node_cols
     }]
end
lambda__nodes =
  lambda do|node_cols|
  {
    type: :json,
    hidden: true,
    remote_dependencies:     [
     lambda__segment_node.call(node_cols)
    ]
  }
end
lambda__instance_nodes_and_components =
  lambda do|node_cols, cmp_cols|
  {
    type: :json,
    hidden: true,
    remote_dependencies: lambda__segments_nodes_and_components.call(node_cols, cmp_cols)
  }
end
lambda__segments_nodes_components_assembly_template =
  lambda do|node_cols, cmp_cols|
   lambda__segments_nodes_and_components.call(node_cols, cmp_cols) + [segment_assembly_template]
end
lambda__instance_nodes_components_assembly_template =
  lambda do|node_cols, cmp_cols|
  {
    type: :json,
    hidden: true,
    remote_dependencies: lambda__segments_nodes_and_components.call(node_cols, cmp_cols) + [segment_assembly_template]
  }
end
{
  virtual_columns: {
    target: {
      type: :json,
      hidden: true,
      remote_dependencies:       [{
         model_name: :datacenter,
         alias: :target,
         convert: true,
         join_type: :inner,
         join_cond: { id: :component__datacenter_datacenter_id },
         cols: [:id, :group_id, :display_name]
       }]
    },
    service_module: {
      type: :json,
      hidden: true,
      remote_dependencies:       [
       {
         model_name: :module_branch,
         convert: true,
         join_type: :inner,
         join_cond: { id: q(:component, :module_branch_id) },
         cols: [:id, :display_name, :service_id, :version]
       },
       {
         model_name: :service_module,
         convert: true,
         join_type: :inner,
         join_cond: { id: q(:module_branch, :service_id) },
         cols: [:id, :group_id, :display_name, :ref, :namespace_id]
       }]
    },
    augmented_ports: {
      type: :json,
      hidden: true,
      remote_dependencies: lambda__segments_nodes_and_components.call([:id, :group_id, :display_name], [:id, :group_id, :display_name, :component_type]) +
      [
        {
         model_name: :port,
         convert: true,
         join_type: :inner,
         join_cond: { node_node_id: :node__id, component_type: :nested_component__component_type },
         cols: Port.common_columns()
        },
        {
          model_name: :link_def,
          convert: true,
          join_type: :left_outer,
          join_cond: { component_component_id: :nested_component__id },
          cols: ([:component_component_id] + LinkDef.common_columns()).uniq
        }
      ]
    },
    augmented_port_links: {
      type: :json,
      hidden: true,
      remote_dependencies:
      [
        {
          model_name: :port_link,
          convert: true,
          join_type: :inner,
          join_cond: { assembly_id: :component__id },
          cols: [:id, :display_name, :group_id, :input_id, :output_id]
        },
        {
          model_name: :port,
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
          join_type: :inner,
          join_cond: { id: :input_port__component_id },
          cols: [:id, :display_name, :group_id, :assembly_id]
        },
        {
          model_name: :node,
          alias: :input_node,
          convert: true,
          join_type: :inner,
          join_cond: { id: :input_port__node_node_id },
          cols: [:id, :display_name, :group_id]
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
          join_type: :inner,
          join_cond: { id: :output_port__component_id },
          cols: [:id, :display_name, :group_id, :assembly_id]
        },
        {
          model_name: :node,
          alias: :output_node,
          convert: true,
          join_type: :inner,
          join_cond: { id: :output_port__node_node_id },
          cols: [:id, :display_name, :group_id]
        }
      ]
    },
    node_attributes: {
      type: :json,
      hidden: true,
      remote_dependencies:       [{
         model_name: :node,
         join_type: :inner,
         join_cond: { assembly_id: :component__id },
         cols: [:id, :display_name, :group_id, :type]
       },
                                  {
                                    model_name: :attribute,
                                    convert: true,
                                    join_type: :inner,
                                    join_cond: { node_node_id: :node__id },
                                    cols: Attribute.common_columns()
                                  }]
    },
    instance_parent: {
      type: :json,
      hidden: true,
      remote_dependencies: [segment_assembly_template]
    },
    instance_nodes_and_assembly_template: {
      type: :json,
      hidden: true,
      remote_dependencies:       [lambda__segment_node.call([:id, :display_name, :os_type, :external_ref, :admin_op_status]),
                                  segment_assembly_template
      ]
    },
    assembly_template_namespace_info: {
      type: :json,
      hidden: true,
      remote_dependencies:        [{
         model_name: :module_branch,
         convert: true,
         join_type: :inner,
         join_cond: { id: :component__module_branch_id },
         cols: [:id, :display_name, :group_id, :version, :current_sha, :service_id]
       },
                                   {
                                     model_name: :service_module,
                                     convert: true,
                                     join_type: :inner,
                                     join_cond: { id: :module_branch__service_id },
                                     cols: [:id, :display_name, :group_id, :namespace_id]
                                   },
                                   {
                                     model_name: :namespace,
                                     convert: true,
                                     join_type: :inner,
                                     join_cond: { id: :service_module__namespace_id },
                                     cols: [:id, :display_name]
                                   }]
    },
    instance_nodes_and_cmps: lambda__instance_nodes_components_assembly_template.call(Node.common_columns, Component.common_columns),
    instance_nodes_and_cmps_summary_with_namespace: {
      type: :json,
      hidden: true,
      remote_dependencies:         lambda__segments_nodes_components_assembly_template.call(
          [:id, :group_id, :display_name, :type, :os_type, :admin_op_status, :external_ref],
          [:id, :group_id, :display_name, :component_type, :basic_type, :extended_base, :description, :version, :module_branch_id]
      ) +
      [{
         model_name: :datacenter,
         alias: :target,
         convert: true,
         join_type: :left_outer,
         join_cond: { id: :component__datacenter_datacenter_id },
         cols: [:id, :group_id, :display_name]
       }] +
       [{
         model_name: :module_branch,
         convert: true,
         join_type: :inner,
         join_cond: { id: :nested_component__module_branch_id },
         cols: [:id, :display_name, :group_id, :version, :current_sha, :component_id]
       },
        {
          model_name: :component_module,
          convert: true,
          join_type: :inner,
          join_cond: { id: :module_branch__component_id },
          cols: [:id, :display_name, :group_id, :namespace_id]
        },
        {
          model_name: :namespace,
          convert: true,
          join_type: :inner,
          join_cond: { id: :component_module__namespace_id },
          cols: [:id, :display_name]
        }]
    },
    instance_nodes_and_cmps_summary: {
      type: :json,
      hidden: true,
      remote_dependencies:         lambda__segments_nodes_components_assembly_template.call(
          [:id, :display_name, :os_type, :admin_op_status, :external_ref],
          [:id, :display_name, :component_type, :basic_type, :extended_base, :description, :version, :module_branch_id]
      ) +
      [{
         model_name: :datacenter,
         alias: :target,
         convert: true,
         join_type: :left_outer,
         join_cond: { id: :component__datacenter_datacenter_id },
         cols: [:id, :group_id, :display_name, :iaas_properties]
       }]
    },
    instance_component_list: lambda__instance_nodes_and_components.call(Node::Instance.component_list_fields(), Component::Instance.component_list_fields()),
    instance_nested_component_attributes: {
      type: :json,
      hidden: true,
      remote_dependencies:         lambda__segments_nodes_and_components.call([:id, :display_name, :group_id, :type], [:id, :display_name, :component_type, :group_id, :only_one_per_node]) +
      [{
        model_name: :attribute,
        convert: true,
        join_type: :inner,
        join_cond: { component_component_id: :nested_component__id },
        cols: Attribute.common_columns()
       }
      ]
    },
    instance_component_module_branches: {
      type: :json,
      hidden: true,
      remote_dependencies:         lambda__segments_nodes_and_components.call([:id, :display_name, :group_id], [:id, :display_name, :component_type, :group_id, :module_branch_id]) +
      [{
         model_name: :module_branch,
         convert: true,
         join_type: :inner,
         join_cond: { id: :nested_component__module_branch_id },
         cols: [:id, :display_name, :group_id, :version, :current_sha, :component_id, :dsl_parsed, :ancestor_id]
       },
       {
         model_name: :component_module,
         convert: true,
         join_type: :inner,
         join_cond: { id: :module_branch__component_id },
         cols: [:id, :display_name, :group_id, :namespace_id]
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
    nested_nodes_summary: lambda__nodes.call([:id, :display_name, :type, :os_type, :admin_op_status, :external_ref]),
    template_stub_nodes: lambda__nodes.call([:id, :group_id, :display_name, :os_type, :external_ref]),
    augmented_component_refs: {
      type: :json,
      hidden: true,
      remote_dependencies:       [
       lambda__segment_node.call([:id, :group_id, :display_name, :os_type, :type]),
       segment_component_ref,
       lambda__segment_component_template.call(:left_outer)
      ]
    },
    # MOD_RESTRUCT: deprecate below for above
    template_nodes_and_cmps_summary: {
      type: :json,
      hidden: true,
      remote_dependencies:       [
       lambda__segment_node.call([:id, :display_name, :os_type]),
       {
         model_name: :component_ref,
         join_type: :inner,
         join_cond: { node_node_id: q(:node, :id) },
         cols: [:id, :display_name, :component_template_id]
       },
       {
         model_name: :component,
         convert: true,
         alias: :nested_component,
         join_type: :inner,
         join_cond: { id: q(:component_ref, :component_template_id) },
         cols: [:id, :display_name, :component_type, :basic_type, :description]
       }]
    },
    template_link_defs_info: {
      type: :json,
      hidden: true,
      remote_dependencies:         [
         lambda__segment_node.call([:id, :display_name]),
         segment_component_ref,
         {
           model_name: :component,
           convert: true,
           alias: :nested_component,
           join_type: :inner,
           join_cond: { id: q(:component_ref, :component_template_id) },
           cols: LinkDef::Info.nested_component_cols()
         },
         {
           model_name: :link_def,
           convert: true,
           join_type: :left_outer,
           join_cond: { component_component_id: q(:nested_component, :id) },
           cols: [:id, :component_component_id, :local_or_remote, :link_type, :has_external_link, :has_internal_link]
         }]
    },
    # MOD_RESTRUCT: this must be removed or changed to reflect more advanced relationship between component ref and template
    component_templates: {
      type: :json,
      hidden: true,
      remote_dependencies:         [
         lambda__segment_node.call([:id, :display_name]),
         segment_component_ref,
         {
           model_name: :component,
           convert: true,
           alias: :component_template,
           join_type: :inner,
           join_cond: { id: q(:component_ref, :component_template_id) },
           cols: [:id, :display_name, :group_id, :component_type, :version, :module_branch_id]
         }]
    },
    tasks: {
      type: :json,
      hidden: true,
      remote_dependencies:       [{
         model_name: :task,
         convert: true,
         join_type: :inner,
         join_cond: { assembly_id: q(:component, :id) },
         cols: [:id, :display_name, :status, :created_at, :started_at, :ended_at, :commit_message]
       }]
    },
    node_templates: {
      type: :json,
      hidden: true,
      remote_dependencies:       [lambda__segment_node.call([:id, :display_name, :type, :os_type, :node_binding_rs_id]),
                                  {
                                    model_name: :node_binding_ruleset,
                                    convert: true,
                                    alias: :node_binding,
                                    join_type: :left_outer,
                                    join_cond: { id: q(:node, :node_binding_rs_id) },
                                    cols: [:id, :display_name, :os_type, :rules]
                                  }]
    },
    components: {
      type: :json,
      hidden: true,
      remote_dependencies:       [{
         model_name: :component,
         convert: true,
         join_type: :inner,
         join_cond: { assembly_id: :component__id },
         cols: [:id, :display_name, :ui, :type]
       }]
    },
    parents_task_templates: {
      type: :json,
      hidden: true,
      remote_dependencies:       [{
         model_name: :component,
         alias: :template,
         join_type: :inner,
         join_cond: { id: :component__ancestor_id },
         cols: [:id, :display_name]
       },
                                  {
                                    model_name: :task_template,
                                    convert: true,
                                    join_type: :inner,
                                    join_cond: { component_component_id: :template__id },
                                    cols: Task::Template.common_columns()
                                  }]
    },
    service_add_ons_from_instance: {
      type: :json,
      hidden: true,
      remote_dependencies:       [{
         model_name: :component,
         alias: :template,
         join_type: :inner,
         join_cond: { id: :component__ancestor_id },
         cols: [:id, :display_name]
       },
                                  {
                                    model_name: :service_add_on,
                                    convert: true,
                                    join_type: :inner,
                                    join_cond: { component_component_id: :template__id },
                                    cols: [:id, :display_name, :type, :description]
                                  }]
    },
    aug_service_add_ons_from_instance: {
      type: :json,
      hidden: true,
      remote_dependencies:       [{
         model_name: :component,
         alias: :template,
         join_type: :inner,
         join_cond: { id: :component__ancestor_id },
         cols: [:id, :group_id, :display_name]
       },
                                  {
                                    model_name: :service_add_on,
                                    convert: true,
                                    join_type: :inner,
                                    join_cond: { component_component_id: :template__id },
                                    cols: [:id, :group_id, :display_name, :type, :sub_assembly_id]
                                  },
                                  {
                                    model_name: :component,
                                    convert: true,
                                    alias: :sub_assembly_template,
                                    join_type: :inner,
                                    join_cond: { id: :service_add_on__sub_assembly_id },
                                    cols: [:id, :group_id, :display_name]
                                  }]
    },
    augmented_with_module_info: {
      type: :json,
      hidden: true,
      remote_dependencies:       [{
         model_name: :module_branch,
         convert: true,
         join_type: :inner,
         join_cond: { id: :component__module_branch_id },
         cols: [:id, :group_id, :display_name, :component_id]
       },
                                  {
                                    model_name: :component_module,
                                    convert: true,
                                    join_type: :inner,
                                    join_cond: { id: :module_branch__component_id },
                                    cols: [:id, :group_id, :display_name, :namespace_id]
                                  },
                                  {
                                    model_name: :namespace,
                                    convert: true,
                                    join_type: :inner,
                                    join_cond: { id: :component_module__namespace_id },
                                    cols: [:id, :group_id, :display_name]
                                  }]
    }
  }
}
