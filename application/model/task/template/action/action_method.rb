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
        config_agent_type_from_provider
      end

      private

      ACTION_PROVIDER_TYPES = [:puppet, :dynamic, :ruby_function, :bash_commands, :workflow]
      def config_agent_type_from_provider
        if provider_string = canonical_provider_name(self[:provider])
          if matching_type = ACTION_PROVIDER_TYPES.find { |type| provider_string == provider_string_name(type) }
            provider_symbol_name(matching_type)
          end
        end
      end

      # TODO: would like to remove this mapping
      CANONICAL_PROVIDER_MAPPING = {
        'dtk' => 'ruby_function'
      }
      def canonical_provider_name(provider_string)
        if provider_string
          CANONICAL_PROVIDER_MAPPING[provider_string] || provider_string
        end
      end

      def provider_symbol_name(provider_type)
        ConfigAgent::Type::Symbol.send(provider_type)
      end

      def provider_string_name(provider_type)
        provider_symbol_name(provider_type).to_s
      end

    end
  end
end; end; end
