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
  module StompDebug
    DEBUG_AGENT_RESPONSE = R8::Config[:debug][:arbiter]

    def inspect_agent_response(msg)
      if DEBUG_AGENT_RESPONSE
        Log.debug 'START: Debugging response from DTK Arbiter'
        Log.debug_pp msg
        Log.debug 'END: Debugging response from DTK Arbiter'
      end
    end
  end
end