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
    class DynamicAttributes
      def initialize(delegated_dynamic_attributes, delegated_task_action_info, base_attributes)
        @delegated_dynamic_attributes = delegated_dynamic_attributes
        @delegated_task_action_info   = delegated_task_action_info
        @base_attributes              = base_attributes
      end
      private :initialize

      def self.transform(delegated_dynamic_attributes, delegated_task_action_info, base_attributes)
        new(delegated_dynamic_attributes, delegated_task_action_info, base_attributes).transform
      end
      def transform
        self.delegated_task_action_info.output_spec.inject([]) do |a, (attribute_name, attribute_value_term)|
          value = Parse::AttributeValue.value?(attribute_value_term, self.delegated_attributes_name_ndx_values)
          value ? a + [{ id: base_attribute_id(attribute_name), attribute_value: value }] : a
        end
      end
      
      protected
      
      attr_reader :delegated_dynamic_attributes, :delegated_task_action_info, :base_attributes

      def delegated_attributes_name_ndx_values
        @delegated_attributes_name_ndx_values ||= self.delegated_dynamic_attributes.inject({}) do |h, delegated_attribute_info|
          delegated_attribute = self.id_ndx_delegated_attributes[delegated_attribute_info[:id]]
          delegated_attribute ? h.merge(delegated_attribute.display_name => delegated_attribute_info[:attribute_value]) : h
        end
      end
      
      def id_ndx_delegated_attributes
        @id_ndx_delegated_attributes ||= self.delegated_task_action_info.component_attributes.inject({}) { |h, attribute| h.merge(attribute.id => attribute) }
      end

      def name_ndx_base_attributes
        @name_ndx_base_attributes ||= self.base_attributes.inject({}) { |h, attribute| h.merge(attribute.display_name => attribute) }
      end

      private
      
      def base_attribute_id(attribute_name)
        (self.name_ndx_base_attributes[attribute_name.to_s] || fail(ErrorUsage, "Undefined attribute '#{attribute_name}' in component action output spec")).id
      end
      
    end
  end
end
