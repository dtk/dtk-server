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
  class Service
    class Component
      r8_nested_require('component', 'attribute')

      attr_reader :type, :dtk_component

      # Argument dtk_component is of type DTK::Component
      def initialize(dtk_component)
        @dtk_component = dtk_component
        @type = ret_type(dtk_component)

        # attributes and links added on demand 
        @attributes = nil
        @link_added = false 
      end

      def self.create_components_from_dtk_components(dtk_components)
        dtk_components.map { |dtk_component| new(dtk_component) }
      end

      def get_attributes
        return @attributes if @attributes 
        dtk_attributes = @dtk_component.get_attributes
        @attributes = Attribute.create_attributes_from_dtk_attributes(dtk_attributes)
      end

      def clear_attribute_cache!
        @attributes = nil
      end

      def add_link_to_component!
        unless @link_added
          Dependency::Link.augment_component_instances!(@dtk_component.get_assembly_instance, [@dtk_component], ret_statisfied_by: true)
          @link_added = true
        end
        self
      end
      
      # Returns dtk component ids that are linked from this by link_def_type
      def get_connected_dtk_component_ids(link_def_type)
        ret = []
        # It is assumed that the dependencies have been added to @dtk_component
        unless dependencies = @dtk_component[:dependencies]
          Log.error("Unexpected that no dependencies in #{@dtk_component.inspect}") 
          return ret
        end
        matching_deps = dependencies.select { |dep| (dep.link_def || {})[:link_type] == link_def_type }
        matching_deps.map { |dep| dep.satisfied_by_component_ids }.flatten(1)
      end

      def get_dtk_aug_attributes(*attribute_names)
        attribute_names = attribute_names.map(&:to_s)
        dtk_component.update_object!(:display_name, :node_node_id)
        nested_component = dtk_component
        node = dtk_component.get_node
        dtk_component.get_attributes.inject([]) do |a, attr|
          attribute_names.include?(attr[:display_name]) ? 
           a + [attr.merge(node: node, nested_component: nested_component)] : a
        end
      end

      private

      def ret_type(dtk_component)
        dtk_component.get_field?(:component_type).gsub('__', '::') if dtk_component
      end
    end
  end
end
