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
        require_relative('component/delegation_action')
        require_relative('component/delegated_config_agent')
        
        def ret_msg_content(task_info, opts = {})
          delegation_action = DelegationAction.new(task_info)
          DelegatedConfigAgent.ret_msg_content(delegation_action, task_info, opts)
        end
        
      end
    end
  end
end
