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
  class CommandAndControlAdapter::Ec2::Reified::Target
    class Component < DTK::Service::Reified::Component::WithServiceComponent
      r8_nested_require('component', 'type')
      r8_nested_require('component', 'vpc')
      r8_nested_require('component', 'vpc_subnet')
      r8_nested_require('component', 'security_group')

      def initialize(reified_target, service_component)
        super(service_component)
        @reified_target = reified_target
      end

      # Returns an array of Violation objects
      def validate_and_converge!
        Log.error("Abstract method that should be overwritten for class '#{self.class}'")
        []
      end

      # For handling Attributes as methods
      def method_missing(attribute_method, *args, &body)
        if legal_attribute_method?(attribute_method) 
          use_and_set_attribute_cache(attribute_method) { get_attribute_value(attribute_method) }
        else
          super
        end
      end

      def respond_to?(attribute_method)
        legal_attribute_method?(attribute_method)
      end

      private

      def legal_attribute_method?(attribute_method)
        self.class::Attributes.include?(attribute_method)
      end

      def clear_all_attribute_caches!
        @reified_target.clear_all_attribute_caches!
      end

      def get_connected_component(component_type)
        link_def_type = Type.name(component_type)
        dtk_component_ids = get_connected_dtk_component_ids(link_def_type)
        components = @reified_target.matching_components(dtk_component_ids)
        if components.size === 0
          # TODO: change to return violation or trap this to return violation
          fail ErrorUsage, "No matching components for '#{component_type}'"
        elsif components.size > 1
          # TODO: change to return violation or tarp this to return violation
          fail ErrorUsage, "Multiple matching components  for '#{component_type}'"
        end
        components.first
      end

      def get_dtk_aug_attributes(*attribute_names)
        # TODO: this is an expensive calculation, but only done when need to generate qualified names
        # used in violation descriptions
        attribute_names = attribute_names.map(&:to_s)
        dtk_component_name = dtk_component.get_field?(:display_name)
        filter_proc = lambda do |assembly_instance| 
          assembly_instance[:nested_component][:display_name] == dtk_component_name and  
            attribute_names.include?(assembly_instance[:attribute][:display_name]) 
        end
        unordered_ret = @reified_target.assembly_instance.get_augmented_nested_component_attributes(filter_proc)
        # Want to order in same order as names
        ndx_unordered_ret = unordered_ret.inject({}) { |h, a| h.merge(a[:display_name] => a) }
        attribute_names.map { |n| ndx_unordered_ret[n] }
      end
      
      def connected_component(conn_cmp_type)
        use_and_set_connected_component_cache(conn_cmp_type) { get_connected_component(conn_cmp_type) }
      end


    end
  end
end

