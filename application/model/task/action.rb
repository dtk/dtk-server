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
  class Task
    class Action < HashObject
      require_relative('action/base')
      # above must go before create_node and config_node
      require_relative('action/config_node')
      require_relative('action/create_node')
      
      # create_node must go before power_on_node
      require_relative('action/power_on_node')
      require_relative('action/on_component')
      require_relative('action/delete_from_database')
      require_relative('action/command_and_control_action')
      require_relative('action/cleanup')

      require_relative('action/result')
      
      # TODO: below might be deprecated
      # physical_node must go first
      require_relative('action/physical_node')
      require_relative('action/install_agent')
      require_relative('action/execute_smoketest')

      def self.create_from_hash(task_action_type, hash, task_idh = nil)
        if action_klass =  NDX_ACTION_CLASSES[task_action_type]
          action_klass.create_from_hash_aux(hash, task_idh)
        elsif task_action_type == 'Hash'
          #TODO: compensating for bug in task creation
          InstallAgent.create_from_hash_aux(hash, task_idh)
        else
          fail Error, "Unexpected task_action_type (#{task_action_type})"
        end
      end

      ACTION_CLASSES = [CreateNode, ConfigNode, PowerOnNode, InstallAgent, DeleteFromDatabase, CommandAndControlAction, Cleanup]
      NDX_ACTION_CLASSES = ACTION_CLASSES.inject({}) { |h, klass| h.merge(Aux.demodulize(klass.to_s) => klass) }

      def self.create_from_hash_aux(hash, task_idh)
        new(:hash, hash, task_idh)
      end
      
      def type
        Aux.underscore(Aux.demodulize(self.class.to_s)).to_sym
      end
      
      # can be overwritten
      def long_running?
        nil
      end
      
      # can be overwritten
      # returns [adapter_type,adapter_name], adapter name optional in which it wil be looked up from config
      def ret_command_and_control_adapter_info
        nil
      end

    end
  end
end
