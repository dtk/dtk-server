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
      require 'debugger'
      Debugger.wait_connection = true
      Debugger.start_remote
      debugger
      commands         = commands(config_node, substitute_template_vars: true)
      component_action = config_node[:component_actions].first
      action_name      = component_action.method_name
      cmp_module       = component_action.component_module_name

      ret = {
        action_agent_request: {
          task_id: opts[:task_id],
          top_task_id: opts[:top_task_id],
          action_name: action_name,
          module_name: cmp_module,
          execution_list: commands
        }
      }

      if assembly = opts[:assembly]
        ret.merge!(service_id: assembly.id(), service_name: assembly.get_field?(:display_name))
      end

      ret
    end

    def type
      Type::Symbol.docker
    end

    private

    def commands(config_node, opts)
      ret = []
      config_node[:component_actions].each do |component_action|
        attr_and_param_vals = component_action.attribute_and_parameter_values
        action_def = component_action.action_def(cols: [:content, :method_name], with_parameters: true)
        # if stdout_and_stderr = true we return combined stdout and stderr in action results
        stdout_and_stderr = stdout_and_stderr(action_def)

        action_def.docker().each do |command|
          if opts[:substitute_template_vars] && command.needs_template_substitution?
            command.bind_template_attributes!(attr_and_param_vals)
          end
          ret << command_msg_form(command, stdout_and_stderr, component_action, attr_and_param_vals)
        end
      end
      ret
    end

    def stdout_and_stderr(action_def)
      # default value is true unless set otherwise in dsl
      ret = (action_def[:content] || {})[:stdout_and_stderr]
      ret.nil? ? true : ret
    end

    def command_msg_form(command, stdout_and_stderr, component_action, attr_and_param_vals)
      cmd_line = command.command_line

      if command.file_positioning?
        cmp_module = component_action.component_module
        repo_info  = cmp_module.get_workspace_repo
        content    = command.get_and_parse_template_content(repo_info[:local_dir], attr_and_param_vals)

        positioning = {
          type: command.type,
          source: {
            type: 'in_payload',
            content: content
          },
          target: {
            path: cmd_line[:target]
          }
        }
        positioning.merge!(owner: command.owner) if command.owner
        positioning.merge!(mode: command.mode) if command.mode

        positioning
      else
        run_command = {
          type: command.type,
          command: cmd_line,
          stdout_redirect: stdout_and_stderr
        }
        run_command.merge!(if: command.if_condition) if command.if_condition
        run_command.merge!(unless: command.unless_condition) if command.unless_condition
        run_command.merge!(timeout: command.timeout) if command.timeout

        run_command
      end
    end
  end
end; end; end