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
  # TODO: remove CommandAndControlAdapter module
  module CommandAndControlAdapter
  end
  class CommandAndControl
    require_relative('command_and_control/adapters/iaas')
    require_relative('command_and_control/adapters/node_config')
    require_relative('command_and_control/install_script')

    def self.create_without_task
      new
    end

    def initialize(task = nil, top_task_idh = nil)
      @top_task_idh = top_task_idh
      if task
        breakpoint   = task[:breakpoint]
        @retry       = task[:retry]
        @task_idh    = task.id_handle
        opts = {
          breakpoint: breakpoint,
          retry: task[:retry],
          attempts: task[:attempts],
          task_params: task[:task_params],
          content_params: task[:content_params],
          top_task_display_name: task[:top_task_display_name]
        }
        @task_action = task[:executable_action].merge(opts)
        @klass       = self.class.load_for(@task_action)
        @attempts    = task[:attempts]
        @task_params = task[:task_params]
        @content_params = task[:content_params]
      end
    end
    attr_reader :task_idh, :top_task_idh, :task_action, :klass, :breakpoint

    def self.execute_task_action(task, top_task_idh)
      new(task, top_task_idh).execute.merge(task_id: task.id)
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

    def self.node_config_server_host
      klass = load_config_node_adapter
      klass.server_host
    end

    def self.node_config_adapter_cloud_config_options(node, bindings)
      klass = load_for_node_config
      klass.cloud_config_options(node, bindings)
    end

    # This takes into account what is needed for the node_config_adapter
    def self.node_config_adapter_install_script(node, bindings)
      klass = load_for_node_config()
      klass.install_script(node, bindings)
    end

    def self.install_script(node, opts={})
      InstallScript.install_script(node, opts)
    end

    def self.discover(filter, timeout, limit, client)
      klass = load_for_node_config
      klass.discover(filter, timeout, limit, client)
    end

    def self.node_action_results(result, action)
      klass = load_for_node_config
      klass.action_results(result, action)
    end

    def self.errors_in_node_action_result?(result, action = nil)
      klass = load_for_node_config
      klass.errors_in_node_action_result?(result, action)
    end

    def self.pbuilderid(node)
      klass = load_iaas_for(node: node)
      klass.pbuilderid(node)
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
      klass = load_for_node_config
      klass.request_execute_action_per_node(agent, action, nodes_hash, callbacks)
    end

    def self.parse_response__execute_action(nodes, msg, params = {})
      klass = load_for_node_config(params[:protocol])
      klass.parse_response__execute_action(nodes, msg)
    end

    def self.initiate_node_action(method, node, callbacks, context)
      klass = load_for_node_config
      klass.send(method, node, callbacks, context)
    end
    # TODO: convert poll_to_detect_node_ready to use more general form above
    def self.poll_to_detect_node_ready(node, opts)
      klass = load_for_node_config
      klass.poll_to_detect_node_ready(node, opts)
    end

    def self.iaas_adapter_name(key_val)
      key = key_val.keys.first
      val = key_val.values.first
      case key
       when :node
        node = val
        case iaas_type = node.get_iaas_type
         when :ec2_instance then :ec2
         when :ec2_image then :ec2
         when :bosh_instance then :bosh
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
    end

    private

    def self.load_iaas_for(key_val)
      load_for_aux(:iaas, iaas_adapter_name(key_val))
    end

    def self.load_for_node_config(protocol_type = nil)
      adapter_name = protocol_type || R8::Config[:command_and_control][:node_config][:type]
      Log.debug("Node config adapter chosen: #{adapter_name}")
      load_for_aux(:node_config, adapter_name)
    end

    def self.load_config_node_adapter
      adapter_type = :node_config
      adapter_name = R8::Config[:command_and_control][adapter_type][:type]
      load_for_aux(adapter_type, adapter_name)
    end

    def self.load_for(task_or_task_action)
      adapter_type, adapter_name = task_or_task_action.ret_command_and_control_adapter_info
      adapter_name ||= R8::Config[:command_and_control][adapter_type][:type]
      fail ErrorCannotLoadAdapter.new unless adapter_type && adapter_name
      load_for_aux(adapter_type, adapter_name)
    end

    def self.load_for_aux(adapter_type, adapter_name)
      Adapters[adapter_type] ||= {}
      return Adapters[adapter_type][adapter_name] if Adapters[adapter_type][adapter_name]
      begin
        r8_nested_require('command_and_control', "adapters/#{adapter_type}/#{adapter_name}")
        if base_class = base_class_when_instance_style_adapter?(adapter_name)
          klass = base_class.const_get adapter_name.to_s.capitalize
          Adapters[adapter_type][adapter_name] = klass.create_without_task
        else
          Adapters[adapter_type][adapter_name] = CommandAndControlAdapter.const_get adapter_name.to_s.capitalize
        end
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
    def self.base_class_when_instance_style_adapter?(adapter_name)
      InstanceStyleAdapters[adapter_name]
    end
    InstanceStyleAdapters = {
      physical: IAAS,
      bosh: IAAS
    }

    #### Error classes
    class Error < DTK::Error
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
end
