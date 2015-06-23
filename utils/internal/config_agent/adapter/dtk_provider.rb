module DTK; class ConfigAgent; module Adapter
  class DtkProvider < ConfigAgent
    r8_nested_require('dtk_provider','interpret_results')
    include InterpretResults::Mixin

    def ret_msg_content(config_node,opts={})
      # TODO: right now noy using assembly attributes; if use, need way to distingusih between refernce to these and
      # reference to component attributes
      # assembly_attrs = assembly_attributes(config_node)

      commands = commands(config_node, :substitute_template_vars => true)
      ret = {
        :action_agent_request => {
          :execution_list => commands,
        }
      }

      if assembly = opts[:assembly]
        ret.merge!(:service_id => assembly.id(), :service_name => assembly.get_field?(:display_name))
      end
      ret
    end

    def type()
      Type::Symbol.dtk_provider
    end

    
    private
    def commands(config_node,opts)
      ret = []
      config_node[:component_actions].each do |component_action|
        attr_val_pairs = nil
        each_command_given_component_action(component_action) do |command|
          attr_val_pairs ||= attribute_value_pairs(component_action)
          if opts[:substitute_template_vars] && command.needs_template_substitution?
            command.bind_template_attributes!(attr_val_pairs)
          end

          # if stdout_and_stderr = true we return combined stdout and stderr in action results
          # default value is true unless set otherwise in dsl
          stdout_and_stderr = true
          action_def = component_action.action_def

          if content = action_def[:content]
            stdout_and_stderr = content[:stdout_and_stderr] unless content[:stdout_and_stderr].nil?
          end

          parse_ret_actions(command, stdout_and_stderr, component_action, attr_val_pairs, ret)
        end
      end
      ret
    end

    def each_command_given_component_action(component_action,&block)
      if action_def = component_action.action_def()
        action_def.commands().each do |command|
          block.call(command)
        end
      end
    end

    def attribute_value_pairs(component_action)
      (component_action[:attributes]||[]).inject(Hash.new) do |h,attr|
        h.merge(attr[:display_name] => attr[:attribute_value])
      end
    end

    def parse_ret_actions(command, stdout_and_stderr, component_action, attr_val_pairs, ret)
      cmd_line = command.command_line
      if command.file_positioning?
        cmp_module = component_action[:component].get_field?(:component_module)
        repo_info  = cmp_module.get_workspace_repo
        content    = command.get_and_parse_template_content(repo_info[:local_dir], attr_val_pairs)

        ret << {
          :type => command.type,
          :source => {
            :type => 'in_payload',
            :content => content
          },
          :target => {
            :path => cmd_line[:target]
          }
        }
      else
        ret << {
          :type => command.type,
          :command => cmd_line,
          :stdout_redirect => stdout_and_stderr
        }
      end
    end
  end
end; end; end
