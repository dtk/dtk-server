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
  class ConfigAgent::Adapter::Component
    class DelegatedConfigAgent
      SUPPORTED_DELEGATE_TO_TYPES = [:dynamic]

      SUPPORTED_DELEGATE_TO_TYPES.each { |type| require_relative("delegated_config_agent/#{type}") }

      def initialize(delegation_action, task_info)
        @delegation_action = delegation_action
        @task_info         = task_info
      end

      def self.ret_msg_content(delegation_action, task_info, opts = {})
        helper_klass(delegation_action.config_agent_type).new(delegation_action, task_info).ret_msg_content(opts)
      end

      def ret_msg_content(opts = {})
        self.config_agent.ret_msg_content(self.transformed_task_info, opts)
      end

      protected
      
      attr_reader :task_info, :delegation_action

      def config_agent_type
        @config_agent_type ||= self.delegation_action.config_agent_type
      end

      def config_agent
        @config_agent ||= ConfigAgent.load(self.config_agent_type)
      end

      def transformed_task_info
        dtk_pp self
        fail "The method 'transform_task_info' should be overwritten by instance method on concrete class '#{self.class}'"
      end

      private

      def self.helper_klass(config_agent_type)
        fail "Delegation to component of type '#{config_agent_type}' not supported" unless SUPPORTED_DELEGATE_TO_TYPES.include?(config_agent_type)
        const_get Aux.camelize(config_agent_type.to_s)
      end

    end
  end
end
