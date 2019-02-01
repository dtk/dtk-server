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
      
      def self.initiate_cancelation(task_idh, top_task_idh, task_action, opts =  {})
        if ConfigAgent::Type.is_a?(task_action.config_agent_type, [:workflow])
          # Rich 1/31: Need to write ConfigAgent::Adapter::Workflow#initiate_cancelation
          # which below calls
          # in initiate_cancelation it shoud use task_idh.get_id (the task id associated with the workflow step)
          # To look up the task id that is associated with the workflow so you can call
          # ::DTK::Workflow.cancel with this task as the argument. This must bhave an id that is in the cache
          #  @@active_workflows in file utils/internal/workflow
          # One way to do this is when ConfigAgent::Adapter::Workflow#execure runs it wil have task_id so when it creates the workflow task
          # it can save in cache @@config_agent_cache a pointer to the workflow task (i.e., task wjose id is in @@active_workflows
          # There was code when this hierechical task was created that looked like it tried to change its id to match task_id. Dont think though changing id works
          # AN alternative approach to task is to have in the task that gets its id inserted into @@active_workflows a filed that you use to point to the task
          # associated with the step that called it
          ConfigAgent.load(:workflow).initiate_cancelation(task_action, task_idh: task_idh)
        else
          # no op
        end
      end
      
    end
  end
end
