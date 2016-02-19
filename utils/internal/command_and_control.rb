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
module DTK
  module CommandAndControlAdapter
  end
  class CommandAndControl
    r8_nested_require('command_and_control', 'install_script')

    def self.create_without_task
      new()
    end

    def initialize(task = nil, top_task_idh = nil)
      @top_task_idh = top_task_idh
      if task
        @task_idh =  task.id_handle()

        @task_action = task[:executable_action]
        @klass = self.class.load_for(@task_action)
      end
    end
    attr_reader :task_idh, :top_task_idh, :task_action, :klass

    def self.execute_task_action(task, top_task_idh)
      new(task, top_task_idh).execute().merge(task_id: task.id())
    end
    def execute
      klass.execute(task_idh, top_task_idh, task_action)
    end

    def self.initiate_task_action(task, top_task_idh, opts = {})
      new(task, top_task_idh).initiate(opts)
    end

    def initiate(opts = {})
      if opts[:cancel_task]
        klass.initiate_cancelation(task_idh, top_task_idh, task_action, opts)
      elsif opts[:sync_agent_task]
        klass.initiate_sync_agent_code(task_idh, top_task_idh, task_action, opts)
      else
        klass.initiate_execution(task_idh, top_task_idh, task_action, opts)
      end
    end

    def self.install_script(node)
      InstallScript.install_script(node)
    end

    def self.discover(filter, timeout, limit, client)
      klass = load_for_node_config()
      klass.discover(filter, timeout, limit, client)
    end

    def self.node_action_results(result, action)
      klass = load_for_node_config()
      klass.action_results(result, action)
    end

    def self.errors_in_node_action_result?(result, action = nil)
      klass = load_for_node_config()
      klass.errors_in_node_action_result?(result, action)
    end

    # This takes into account what is needed for the node_config_adapter
    def self.node_config_adapter_install_script(node, bindings)
      klass = load_for_node_config()
      klass.install_script(node, bindings)
    end

    def self.pbuilderid(node)
      klass = load_iaas_for(node: node)
      klass.pbuilderid(node)
    end

    def self.raise_error_if_invalid_image?(image_id, target)
      klass = load_iaas_for(target: target)
      klass.raise_error_if_invalid_image?(image_id, target)
    end
    def self.existing_image?(image_id, target)
      klass = load_iaas_for(target: target)
      klass.existing_image?(image_id, target)
    end

    def self.references_image?(target, node_external_ref)
      klass = load_iaas_for(target: target)
      klass.references_image?(node_external_ref)
    end

    def self.start_instances(nodes)
      klass = load_iaas_for(node: nodes.first)
      klass.start_instances(nodes)
    end

    def self.stop_instances(nodes)
      klass = load_iaas_for(node: nodes.first)
      klass.stop_instances(nodes)
    end

    def self.check_iaas_properties(iaas_type, iaas_properties, opts = {})
      klass = load_for_aux(:iaas, iaas_type.to_s)
      klass.check_iaas_properties(iaas_properties, opts)
    end

    def self.get_and_process_availability_zones(iaas_type, iaas_properties, region)
      klass = load_for_aux(:iaas, iaas_type.to_s)
      klass.get_availability_zones(iaas_properties, region)
    end

    def self.find_matching_node_binding_rule(node_binding_rules, target)
      target.update_object!(:iaas_type, :iaas_properties)
      klass = load_iaas_for(target: target)
      klass.find_matching_node_binding_rule(node_binding_rules, target)
    end

    def self.node_config_server_host
      klass = load_config_node_adapter()
      klass.server_host()
    end

    def self.destroy_node?(node, opts = {})
      klass = load_iaas_for(node: node)
      klass.destroy_node?(node, opts)
    end

    def self.associate_persistent_dns?(node)
      klass = load_iaas_for(node: node)
      klass.associate_persistent_dns?(node)
    end

    def self.associate_elastic_ip(node)
      klass = load_iaas_for(node: node)
      klass.associate_elastic_ip(node)
    end

    def self.get_and_update_node_state!(node, attribute_names)
      # TODO: Haris - Test more this change
      adapter_name = node.get_target_iaas_type() || R8::Config[:command_and_control][:iaas][:type]
      klass = load_for_aux(:iaas, adapter_name)
      klass.get_and_update_node_state!(node, attribute_names)
    end

    def self.get_node_operational_status(node)
      adapter_name = R8::Config[:command_and_control][:iaas][:type]
      klass = load_for_aux(:iaas, adapter_name)
      klass.get_node_operational_status(node)
    end

    def self.request__get_logs(task, nodes, callbacks, context)
      klass = load_for(task)
      klass.request__get_logs(task, nodes, callbacks, context)
    end

    def self.parse_response__get_logs(task, msg)
      klass = load_for(task)
      klass.parse_response__get_logs(msg)
    end

    def self.request__execute_action(agent, action, nodes, callbacks, params = {})
      klass = load_for_node_config(params[:protocol])
      klass.request__execute_action(agent, action, nodes, callbacks, params)
    end

    def self.request__execute_action_per_node(agent, action, nodes_hash, callbacks)
      klass = load_for_node_config()
      klass.request_execute_action_per_node(agent, action, nodes_hash, callbacks)
    end

    def self.parse_response__execute_action(nodes, msg, params = {})
      klass = load_for_node_config(params[:protocol])
      klass.parse_response__execute_action(nodes, msg)
    end

    def self.initiate_node_action(method, node, callbacks, context)
      klass = load_for_node_config()
      klass.send(method, node, callbacks, context)
    end
    # TODO: convert poll_to_detect_node_ready to use more general form above
    def self.poll_to_detect_node_ready(node, opts)
      klass = load_for_node_config()
      klass.poll_to_detect_node_ready(node, opts)
    end

    private

    def self.load_for_node_config(protocol_type = nil)
      adapter_name = protocol_type || R8::Config[:command_and_control][:node_config][:type]
      Log.debug("Node config adapter chosen: #{adapter_name}")
      load_for_aux(:node_config, adapter_name)
    end

    def self.load_iaas_for(key_val)
      key = key_val.keys.first
      val = key_val.values.first
      adapter_name =
        case key
          when :node
            node = val
            case iaas_type = node.get_iaas_type()
              when :ec2_instance then :ec2
              when :ec2_image then :ec2 #TODO: kept in because staged node has this type, which should be changed
              when :physical then :physical
              else fail Error.new("iaas type (#{iaas_type}) not treated")
            end
          when :target
            target =  val
            iaas_type = target.get_field?(:iaas_type)
            case iaas_type
              when 'ec2' then :ec2
              when 'physical' then :physical
              else fail Error.new("iaas type (#{iaas_type}) not treated")
            end
          when :image_type
            image_type = val
            case image_type
              when :ec2_image then :ec2
              else fail Error.new("image type (#{key_val[:image_type]}) not treated")
            end
          else
            fail Error.new("#{key_val.inspect} not treated")
        end
      adapter_type = :iaas
      load_for_aux(adapter_type, adapter_name)
    end

    def self.load_config_node_adapter
      adapter_type = :node_config
      adapter_name = R8::Config[:command_and_control][adapter_type][:type]
      load_for_aux(adapter_type, adapter_name)
    end

    def self.load_for(task_or_task_action)
      adapter_type, adapter_name = task_or_task_action.ret_command_and_control_adapter_info()
      adapter_name ||= R8::Config[:command_and_control][adapter_type][:type]
      fail ErrorCannotLoadAdapter.new unless adapter_type && adapter_name
      load_for_aux(adapter_type, adapter_name)
    end

    def self.load_for_aux(adapter_type, adapter_name)
      Adapters[adapter_type] ||= {}
      return Adapters[adapter_type][adapter_name] if Adapters[adapter_type][adapter_name]
      begin

        r8_nested_require('command_and_control', "adapters/#{adapter_type}/#{adapter_name}")
        klass = CommandAndControlAdapter.const_get adapter_name.to_s.capitalize
        klass_or_instance = (instance_style_adapter?(adapter_type, adapter_name) ? klass.create_without_task() : klass)
        Adapters[adapter_type][adapter_name] =  klass_or_instance
       rescue LoadError => e
        raise ErrorUsage.new("IAAS type ('#{adapter_name}') not supported! Reason #{e.message}!")
       rescue Exception => e
        raise e
      end
    end

    def self.filter_single_fact(fact, value, operator = nil)
      { 'fact' => [format_fact_filter(fact, value, operator)] }
    end

    def self.format_fact_filter(fact, value, operator = nil)
      if operator.nil?
        operator = value.is_a?(Regexp) ? '=~' : '=='
      end
      if value.is_a?(Regexp)
        value = "/#{value.source}/"
      end
      { fact: fact, value: value.to_s, operator: operator }
    end

    Adapters = {}
    Lock = Mutex.new

    # TODO: want to convert all adapters to new style to avoid setting stack error when adapter method not defined to have CommandAndControlAdapter self call instance
    def self.instance_style_adapter?(adapter_type, adapter_name)
      (InstanceStyleAdapters[adapter_type.to_sym] || []).include?(adapter_name.to_sym)
    end
    InstanceStyleAdapters = {
      iaas: [:physical]
    }

    #### Error classes
    class Error < XYZ::Error
      def to_hash
        { error_type: Aux.demodulize(self.class.to_s) }
      end
      class CannotConnect < Error
      end
      class Communication < Error
      end
      class CannotLoadAdapter < Error
      end
      class Timeout < Error
      end
      class FailedResponse < Error
        def initialize(error_msg)
          super()
          @error_msg = error_msg
        end

        def to_hash
          super().merge(error_msg: @error_msg)
        end
      end
      class CannotCreateNode < Error
      end
      class WhileCreatingNode < Error
      end
    end
  end

  class CommandAndControlNodeConfig < CommandAndControl

    def self.mc_info_for_config_agent(config_agent)
      type = config_agent.type()
      ConfigAgentTypeToMCInfo[type] || fail(Error.new("unexpected config adapter: #{type}"))
    end

    ConfigAgentTypeToMCInfo = {
      puppet: { agent: 'puppet_apply', action: 'run' },
      dtk_provider: { agent: 'action_agent', action: 'run_command' },
      chef: { agent: 'chef_solo', action: 'run' }
    }

  end

  class CommandAndControlIAAS < CommandAndControl
  end
end