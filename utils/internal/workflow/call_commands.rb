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
  class Workflow
    module CallCommandsMixin
      #synchronous
      def process_executable_action(task)
        CallCommands.execute_task_action(task, top_task_idh)
      end

      #asynchronous
      def initiate_executable_action(task, receiver_context)
        opts = {
          initiate_only: true,
          receiver_context: receiver_context
        }
        CallCommands.initiate_task_action(task, top_task_idh, opts)
      end


      def initiate_cancel_action(task, receiver_context)
        opts = {
          cancel_task: true,
          receiver_context: receiver_context
        }
        CallCommands.initiate_task_action(task, top_task_idh, opts)
      end

      def initiate_sync_agent_action(task, receiver_context)
        opts = {
          sync_agent_task: true,
          receiver_context: receiver_context
        }
        CallCommands.initiate_task_action(task, top_task_idh, opts)
      end

      def initiate_node_action(method, node, callbacks, context)
        CallCommands.initiate_node_action(method, node, callbacks, context)
      end

      def poll_to_detect_node_ready(node, receiver_context, opts = {})
        poll_opts = opts.merge(receiver_context: receiver_context)
        CallCommands.poll_to_detect_node_ready(node, poll_opts)
      end

      class CallCommands
        def self.execute_task_action(task, top_task_idh)
          CommandAndControl.execute_task_action(task, top_task_idh)
        end

        def self.initiate_task_action(task, top_task_idh, opts = {})
          CommandAndControl.initiate_task_action(task, top_task_idh, opts)
        end

        def self.initiate_node_action(method, node, callbacks, context)
          CommandAndControl.initiate_node_action(method, node, callbacks, context)
        end

        def self.poll_to_detect_node_ready(node, poll_opts)
          CommandAndControl.poll_to_detect_node_ready(node, poll_opts)
        end
      end
    end
  end
end
