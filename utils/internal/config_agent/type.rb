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
    module Type
      def self.is_a?(config_agent_type, type_or_types) 
        if type_or_types.kind_of?(Array)
          type_or_types.find { |type| is_this_type?(config_agent_type, type) }
        else
          is_this_type?(config_agent_type, type_or_types)
        end
      end

      private
      
      def self.is_this_type?(config_agent_type, type)
        if config_agent_type && (config_agent_type.to_sym == Symbol.send(type))
          config_agent_type.to_sym
        end
      end

      module Symbol
        All = [:puppet, :bash_commands, :no_op, :ruby_function, :docker, :chef, :serverspec, :test, :node_module, :delete_from_database, :command_and_control_action, :cleanup]
        Default = :puppet
        All.each do |type|
          class_eval("def self.#{type}();:#{type};end")
        end
      end
      def self.default_symbol
        Symbol::Default
      end
    end
  end
end