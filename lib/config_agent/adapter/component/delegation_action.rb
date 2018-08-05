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
  class ConfigAgent::Adapter::Component
    class DelegationAction
      require_relative('delegation_action/inputs')

      def initialize(task_info, assembly_instance)
        @task_info         = task_info
        @assembly_instance = assembly_instance
      end
      private :initialize

      def self.parse(task_info, assembly_instance)
        new(task_info, assembly_instance).parse
      end
      def parse
        @config_agent_type = ret_config_agent_type
        @inputs            = Inputs.bind(self.input_spec, self.base_input_values) 
        self
      end
      
      attr_reader :config_agent_type, :inputs
      
      protected
      
      attr_reader :task_info, :assembly_instance
      
      def base_input_values
        require 'byebug'; byebug
        @base_input_values ||= self.action_properties[:type] || raise_parsing_error("Cannot find the :component_type property")
      end

      def input_spec
        @input_spec ||= self.action_properties[:inputs] || raise_parsing_error("Cannot find the :inputs property")
      end

      def action_component_template
        @action_component_template ||= ret_action_component_template
      end

      def component_type
        @component_type ||= self.action_properties[:type] || raise_parsing_error("Cannot find the :component_type property")
      end

      def component_action
        @component_action ||= ret_component_action
      end

      def action_properties
        @action_properties ||= ret_action_properties? || fail("Unexpected that cannot find teh action proepreties")
      end

      DEFAULT_ACTION_METHOD = 'create'
      def action_method
        @action_method ||= self.action_properties[:method] || DEFAULT_ACTION_METHOD
      end

      private

      def ret_config_agent_type
        require 'byebug'; byebug
        config_agent_type = 
          if self.action_method == 'create'
            external_ref = self.action_component_template.get_field?(:external_ref) || fail(Error, "Unexpected that external_ref not defined on action component with create method")
            external_ref[:provider] || fail(Error, "Unexpected that external_ref[:provider] is nil")
          else 
            fail Error, "Component actions other than create ones not supported yet"
          end
        config_agent_type.to_sym
      end


      def ret_action_component_template
        self.assembly_instance.simple_find_matching_aug_component_template(internal_component_type_form(self.component_type))
      end

      def ret_action_properties?
        # TODO: just looking in external ref; need to also look at action defs for non create
        (self.component_action[:component] || {})[:external_ref]
      end

      def ret_component_action 
        component_actions = self.task_info[:component_actions] || []
        case component_actions.size
          when 1
          component_actions.first
          when 0
          fail "Unexepected that there are no component actions"
        else
          fail "Unexepected that there are multiple component actions"
        end
      end

      def internal_component_type_form(component_type)
        component_type.sub(/::/, '__')
      end

      def raise_parsing_error(err_mesage)
        fail ErrorUsage, "Parsing error in the component action: #{err_mesage}" 
      end

    end
  end
end
