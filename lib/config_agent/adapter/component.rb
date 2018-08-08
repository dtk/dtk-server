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
  class ConfigAgent
    module Adapter
      class Component < ConfigAgent
        require_relative('component/delegated_config_agent')
        require_relative('component/dynamic_attributes')
        require_relative('component/parse')
        
        def ret_msg_content(task_action, opts = {})
          assembly_instance  = opts[:assembly] || fail("Unexpected that opts[:assembly] is nil")          
          task_id            = opts[:task_id] || fail("Unexpected that opts[:task_id] is nil")          
          task_idh           = assembly_instance.id_handle.createIDH(model_name: :task, id: task_id)

          parsed_task_action = Parse.new(task_action, assembly_instance, task_idh)

          @delegated_task_action_info = parsed_task_action.delegated_task_action_info
          @base_component_attributes  = parsed_task_action.base_component_attributes
          
          DelegatedConfigAgent.ret_msg_content(@delegated_task_action_info, opts)
        end

        def type
          self.delegated_config_agent_type
        end

        def get_dynamic_attributes(payload, _action)
          if self.delegated_config_agent.respond_to?(:get_dynamic_attributes)
            delegated_dynamic_attributes = self.delegated_config_agent.get_dynamic_attributes(payload, self.delegated_task_action)
            DynamicAttributes.transform(delegated_dynamic_attributes, self.delegated_task_action_info, self.base_component_attributes)
          else
            []
          end
        end

        protected

        def delegated_config_agent_type
          @delegated_config_agent_type ||= self.delegated_task_action_info.config_agent_type
        end

        def delegated_task_action
          @delegated_task_action ||= self.delegated_task_action_info.task_action
        end

        def delegated_config_agent
          @delegated_config_agent ||= ConfigAgent.load(self.delegated_config_agent_type)
        end

        def delegated_task_action_info
          @delegated_task_action_info || fail("Unexpected that @delegated_task_action_info is not set")
        end

        def base_component_attributes
          @base_component_attributes || fail("Unexpected that @base_component_attributes is not set")
        end

      end
    end
  end
end
