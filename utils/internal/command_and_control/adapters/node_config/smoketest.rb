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
    class Smoketest < CommandAndControl::NodeConfig
      def self.initiate_execution(task_idh, top_task_idh, task_action, opts)
        SSHDriverTest1.smoketest_start(task_idh, top_task_idh, task_action, opts)
      end
    end
  end
end

module DTK
  class SSHDriverTest1
    def self.smoketest_start(_task_idh, _top_task_idh, task_action, opts)
      unless callbacks = (opts[:receiver_context] || {})[:callbacks]
        fail Error.new('Unexpected that no calls given')
      end

      if parent = (opts[:receiver_context] || {})[:parent]
        if parent[:status].eql?('failed') || parent[:status].eql?('canceled')
          msg = { msg: parent[:status] }
          callbacks[:on_cancel].call(msg)
          return
        end
      end

      node = task_action[:node]
      node.update_object!(:ref)

      CommandAndControl.poll_to_detect_node_ready(node, opts)
    end

    def self.test_cancel(_task_idh, _top_task_idh, _task_action, opts)
      puts '===================== SSH CANCEL CALLED ===================='
      callbacks = (opts[:receiver_context] || {})[:callbacks]
      # should not use EM.stop for cancel, need to find better solution
      # EM.stop
      @connections.each do |conn|
        # need Fiber.new to avoid message 'can't yield from root fiber'
        Fiber.new do
          conn[:ssh].close
          conn[:connection].close
        end.resume
      end

      msg = { msg: 'CANCEL' }
      callbacks[:on_msg_received].call(msg)
    end
  end
end
