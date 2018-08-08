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
      def initialize(delegated_task_action_info, base_ret_msg_content_opts)
        @delegated_task_action_info    = delegated_task_action_info
        @base_ret_msg_content_opts     = base_ret_msg_content_opts
      end

      def self.ret_msg_content(delegated_task_action_info, opts = {})
        new(delegated_task_action_info, opts).ret_msg_content
      end

      def ret_msg_content
        self.config_agent.ret_msg_content(self.delegated_task_action_info.task_action, self.delegated_ret_msg_content_opts)
      end

      protected
      
      attr_reader :delegated_task_action_info, :base_ret_msg_content_opts

      def config_agent_type
        @config_agent_type ||= ret_config_agent_type
      end

      def config_agent
        @config_agent ||= ConfigAgent.load(self.config_agent_type)
      end

      def delegated_ret_msg_content_opts
        self.base_ret_msg_content_opts.merge(delegated: true)
      end

      private

      def ret_config_agent_type
        config_agent_type = self.delegated_task_action_info.config_agent_type
        fail "Delegation to component of type '#{config_agent_type}' not supported" unless SUPPORTED_DELEGATE_TO_TYPES.include?(config_agent_type)
        config_agent_type
      end

    end
  end
end
