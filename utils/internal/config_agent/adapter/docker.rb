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
module DTK; class ConfigAgent; module Adapter
  class Docker < ConfigAgent
    def ret_msg_content(config_node, opts = {})
      component_action = config_node[:component_actions].first
      cmp_module       = component_action.component_module_name

      cmp              =  component_action[:component]
      template_idh     =  cmp.id_handle(id: cmp[:ancestor_id])
      cmps_action_defs =  ActionDef.get_ndx_action_defs([template_idh])

      action_def = nil
      action_name = nil

      cmps_action_defs.values.flatten.each do |a_def|
        action_name = a_def[:method_name]||a_def[:display_name]

        # for now support docker only for create action
        if action_name.eql?('create') && !a_def.docker.empty?
          action_def = a_def
          break
        end
      end

      fail ErrorUsage.new("Unexpected to call docker adapter without docker actions!") unless action_def

      docker_execs         = action_def.docker
      docker_exec          = docker_execs.first
      docker_file_template = substitute_template_values(docker_exec.docker_file_template, component_action.attribute_and_parameter_values)

      msg_content = {
        module_name: cmp_module,
        action_name: action_name,
        top_task_id: opts[:top_task_id],
        task_id: opts[:task_id],
        docker_image: docker_exec.docker_image,
        execution_type: 'bash',
        dockerfile: docker_file_template,
        docker_run_params: docker_exec.docker_run_params,
        entrypoint: docker_exec.entrypoint,
        version_context: get_version_context(config_node, opts[:assembly]),
      }

      if assembly = opts[:assembly]
        msg_content.merge!(service_id: assembly.id(), service_name: assembly.get_field?(:display_name))
      end

      msg_content
    end

    def type
      Type::Symbol.docker
    end

    private

    def get_version_context(config_node, assembly_instance)
      ret =  []
      component_actions = config_node[:component_actions]
      if component_actions.empty?()
        return ret
      end
      unless (config_node[:state_change_types] & %w(install_component update_implementation converge_component setting)).size > 0
        return ret
      end

      # want components to be unique
      components = component_actions.inject({}) { |h, r| h.merge(r[:component][:id] => r[:component]) }.values
      ComponentModule::VersionContextInfo.get_in_hash_form(components, assembly_instance)
    end

    def substitute_template_values(docker_file_template, attributes)
      if MustacheTemplate.needs_template_substitution?(docker_file_template)
        begin
          docker_file_template = MustacheTemplate.render(docker_file_template, attributes)
        rescue MustacheTemplateError::MissingVar => e
          ident = 4
          err_msg = "The variable '#{e.missing_var}' in the following workflow term is not set:\n#{' ' * ident}#{string}"
          fail ErrorUsage.new(err_msg)
        end
      end

      docker_file_template
    end
  end
end; end; end
