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
module DTK; class ConfigAgent; module Adapter
  class CommandAndControlAction < ConfigAgent
    def execute(task_action, top_task_idh, task_idh)
      task_action.execute_command_and_control_action(top_task_idh, task_idh)

      {
        statuscode: 0,
        statusmsg: 'OK',
        data: { status: :succeeded }
      }
    end
  end
end; end; end