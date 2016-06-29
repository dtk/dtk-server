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
  class CommandAndControl
    class NodeConfig < self
      def self.mc_info_for_config_agent(config_agent)
        require 'debugger'
        Debugger.wait_connection = true
        Debugger.start_remote
        debugger
      type = config_agent.type()
        ConfigAgentTypeToMCInfo[type] || fail(Error.new("unexpected config adapter: #{type}"))
      end
      
      ConfigAgentTypeToMCInfo = {
        puppet: { agent: 'puppet_apply', action: 'run' },
        dtk_provider: { agent: 'action_agent', action: 'run_command' },
        chef: { agent: 'chef_solo', action: 'run' },
        docker: { agent: 'docker_agent', action: 'run' },
      }
    end
  end
end

