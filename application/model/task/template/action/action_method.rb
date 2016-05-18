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
module DTK; class Task; class Template
  class Action
    class ActionMethod < Hash
      def initialize(action_def)
        super()
        hash =  {
          method_name: action_def.get_field?(:method_name),
          action_def_id: action_def.id(),
          provider: (action_def.content||{})[:provider]
        }
        replace(hash)
      end

      def method_name
        self[:method_name]
      end

      def config_agent_type
        return :puppet if self[:provider].eql?('puppet')
        ConfigAgent::Type::Symbol.dtk_provider
      end
    end
  end
end; end; end