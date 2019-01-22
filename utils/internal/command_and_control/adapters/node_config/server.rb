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
    class Server < CommandAndControl::NodeConfig
      def self.execute(task_idh, top_task_idh, task_action)
        response = nil
        config_agent_type = task_action.config_agent_type
        if type = ConfigAgent::Type.is_a?(config_agent_type, [:ruby_function, :no_op])
          response = ConfigAgent.load(:ruby_function).execute(task_action)
        elsif type = ConfigAgent::Type.is_a?(config_agent_type, [:workflow])
          response = ConfigAgent.load(:workflow).execute(task_action, {task_idh: task_idh})
        elsif type = ConfigAgent::Type.is_a?(config_agent_type, [:delete_from_database])
          response = ConfigAgent.load(:delete_from_database).execute(task_action, top_task_idh)
        elsif type = ConfigAgent::Type.is_a?(config_agent_type, [:command_and_control_action])
          response = ConfigAgent.load(:command_and_control_action).execute(task_action, top_task_idh, task_idh)
        elsif type = ConfigAgent::Type.is_a?(config_agent_type, [:cleanup])
          response = ConfigAgent.load(:cleanup).execute(task_action, top_task_idh)
        else
          Log.error("Not treating server execution of config_agent_type '#{config_agent_type}'")
        end

        # unless response is returned from ruby function send status: OK
        response ||= {
          statuscode: 0,
          statusmsg: 'OK"',
          data: { status: :succeeded }
        }
        response
      end
    end
  end
end
