module DTK; class ConfigAgent; module Adapter
  class DtkProvider < ConfigAgent
    r8_nested_require('dtk_provider', 'interpret_results')
    include InterpretResults::Mixin

    def ret_msg_content(config_node, opts = {})
      commands         = commands(config_node, substitute_template_vars: true)
      component_action = config_node[:component_actions].first
      action_name      = component_action[:action_method][:method_name]
      cmp_module       = component_action[:component].get_field?(:component_module).full_module_name

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
      Type::Symbol.dtk_provider
    end

    private

    def commands(config_node, opts)
      ret = []
      config_node[:component_actions].each do |component_action|
        attr_val_pairs = attribute_value_pairs(component_action)
        action_def = component_action.action_def(cols: [:content, :method_name], with_parameters: true)
pp [:xxxxxxxxxx,:action_def,action_def]
        # if stdout_and_stderr = true we return combined stdout and stderr in action results
        stdout_and_stderr = stdout_and_stderr(action_def)

        action_def.commands().each do |command|
          if opts[:substitute_template_vars] && command.needs_template_substitution?
            command.bind_template_attributes!(attr_val_pairs)
          end
          ret << command_msg_form(command, stdout_and_stderr, component_action, attr_val_pairs)
        end
      end
      ret
    end

    def stdout_and_stderr(action_def)
      # default value is true unless set otherwise in dsl
      ret = (action_def[:content] || {})[:stdout_and_stderr]
      ret.nil? ? true : ret
    end

    def attribute_value_pairs(component_action)
      (component_action[:attributes] || []).inject({}) do |h, attr|
        h.merge(attr[:display_name] => attr[:attribute_value])
      end
    end

    def command_msg_form(command, stdout_and_stderr, component_action, attr_val_pairs)
      cmd_line = command.command_line

      if command.file_positioning?
        cmp_module = component_action[:component].get_field?(:component_module)
        repo_info  = cmp_module.get_workspace_repo
        content    = command.get_and_parse_template_content(repo_info[:local_dir], attr_val_pairs)

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
