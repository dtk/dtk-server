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
  class ConfigAgent::Adapter::Dynamic
    module AttributeRequestForm
      class Info < ::Hash
        def initialize(value, datatype, hidden)
          super()
          replace(value: value, datatype: datatype, hidden: hidden)
        end
      end

      # TODO: DTK-2938; might remove this special logic around node component

      # opts can have keys:
      #   :node_component
      def self.transform_attribute(attribute, opts = {})
        { attribute.display_name => attribute_info(attribute, opts) }
      end
      
      def self.component_attribute_values(component_action, service_instance_name)
        node_component = NodeComponent.node_component?(component_action.component)
        component_action.attributes.inject(service_wide_attribute_values(service_instance_name)) do |h, attr|
          # prune dynamic attributes that are not also inputs
          (attr[:dynamic] and !attr[:dynamic_input]) ? h : h.merge(transform_attribute(attr, node_component:  node_component))
        end
      end

      private

      # opts can have keys:
      #   :node_component
      def self.attribute_info(attribute, opts = {})
        value = factor_in_node_component_special_value(attribute, opts)
        Info.new(value, attribute[:data_type], attribute[:hidden])
      end
    
      def self.factor_in_node_component_special_value(attribute, opts = {})
        attribute.update_obj!(:value_derived, :value_asserted)
        value = attribute[:attribute_value]
        return value unless node_component = opts[:node_component]
        is_special_value, special_value = node_component.update_if_dynamic_special_attribute!(attribute)
        is_special_value ? special_value : value
      end

      SERVICE_WIDE_ATTRIBUTES = {
        dtk_service_instance: {
          value_lambda: lambda { |service_instance_name| service_instance_name }, 
          dattype: 'string', 
          hidden: false
        }
      }
      
      def self.service_wide_attribute_values(service_instance_name)
        SERVICE_WIDE_ATTRIBUTES.inject({}) do | h, (attr_name, input)|
          h.merge(attr_name.to_s => Info.new(input[:value_lambda].call(service_instance_name), input[:datatype], input[:hidden]))
        end
      end
      

    end
  end
end        
