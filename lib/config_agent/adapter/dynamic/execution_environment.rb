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
  module ConfigAgent::Adapter
    class Dynamic
      module ExecutionEnvironment
        require_relative('execution_environment/breakpoint_processing')

        EPHEMERAL_CONTAINER = 'ephemeral_container'
        NATIVE              = 'native'
        # opts can have keys
        #   :breakpoint (Boolean)
        def self.execution_environment(dynamic_provider, node, opts = {})
          BreakpointProcessing.process!(dynamic_provider) if opts[:breakpoint] 

          provider_type = dynamic_provider.type
          if node.is_assembly_wide_node?            
            docker_file = dynamic_provider.docker_file? || fail(ErrorUsage, "Cannot find the docker file for the #{provider_type} provider")
            { type: EPHEMERAL_CONTAINER, docker_file: docker_file }
          else
            bash_script = dynamic_provider.bash_script?  || fail(ErrorUsage, "Cannot find the bash script for the #{provider_type} provider")
            { type: NATIVE, bash: bash_script }
          end
        end

      end
    end
  end
end
