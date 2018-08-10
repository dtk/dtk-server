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
    class Parse
      require_relative('parse/attribute_mapping')
      require_relative('parse/attribute_value')

      def initialize(task_action, assembly_instance, task_idh)
        @task_action       = task_action
        @assembly_instance = assembly_instance
        @task_idh          = task_idh
      end

      DelegatedTaskActinInfo = Struct.new(:config_agent_type, :task_action, :component_attributes, :output_spec)
      def delegated_task_action_info
        DelegatedTaskActinInfo.new(self.delegated_config_agent_type, self.delegated_task_action, self.delegated_attributes, self.output_spec) 
      end

      def base_component_attributes
        @base_component_attributes ||= self.component_action[:attributes] || []
      end
      
      protected
      
      attr_reader :task_action, :assembly_instance, :task_idh

      def delegated_config_agent_type
        config_agent_type = 
          if self.action_method == 'create'
            external_ref = self.delegated_component_template.get_field?(:external_ref) || fail(Error, "Unexpected that external_ref not defined on action component with create method")
            external_ref[:provider] || fail(Error, "Unexpected that external_ref[:provider] is nil")
          else 
            fail Error, "Component actions other than create ones not supported yet"
          end
        config_agent_type.to_sym
      end

      def delegated_task_action
        task_action_type = 
          case self.task_action
          when Task::Action::ConfigNode
            'ConfigNode'
          else 
            fail Error, "Task having class #{self.task_action.class} not treated"
          end
        create_hash_params = {
          component_actions: [self.delegated_component_action],
          node: self.task_action[:node], # TODO: using same node as what is on base action; see if this should be more flexable such as using link defs from delegated component
          breakpoint: self.task_action[:breakpoint],
          retry: self.task_action[:retry],
          attempts: self.task_action[:attempts]
        }  
        Task::Action.create_from_hash(task_action_type, create_hash_params, self.task_idh)
      end

      def delegated_component_action
        {
          attributes: self.delegated_attributes,
          component: self.delegated_component,
        }
        
      end

      def delegated_attributes
        @delegated_attributes ||= fold_in_values(self.delegated_attributes_wo_values, self.attribute_mapping)
      end

      def delegated_component
        self.delegated_component_template
      end

      def delegated_attributes_wo_values
        self.delegated_component_template.get_attributes
      end

      def delegated_component_template
        @delegated_component_template ||= ret_delegated_component_template
      end

      def attribute_mapping
        @attribute_mapping ||= AttributeMapping.attribute_mapping(self.input_spec, self.base_component_attributes) 
      end

      def input_spec
        @input_spec ||= self.action_properties[:inputs] || raise_parsing_error("Cannot find the :inputs property")
      end

      def output_spec
        @output_spec ||= self.action_properties[:outputs] || {}
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

      def fold_in_values(delegated_attributes_wo_values, attribute_mapping)
        delegated_attributes_wo_values.map do |attribute|
          attribute_name = attribute.display_name
          attribute_mapping.has_key?(attribute_name) ? attribute.merge(:value_asserted => attribute_mapping[attribute_name]) : attribute
        end
      end

      def ret_delegated_component_template
        self.assembly_instance.simple_find_matching_aug_component_template(internal_component_type_form(self.component_type))
      end

      def ret_action_properties?
        # TODO: just looking in external ref; need to also look at action defs for non create
        (self.component_action[:component] || {})[:external_ref]
      end

      def ret_component_action 
        component_actions = self.task_action[:component_actions] || []
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
