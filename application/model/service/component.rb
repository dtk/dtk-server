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
        # @attributes is computed on demand
        @attributes = nil
      end

      def self.create_components_from_dtk_components(dtk_components)
        dtk_components.map { |dtk_component| new(dtk_component) }
      end

      def get_attributes
        return @attributes if @attributes 
        dtk_attributes = @dtk_component.get_component_with_attributes_unraveled({})[:attributes]
        @attributes = Attribute.create_attributes_from_dtk_attributes(dtk_attributes)
      end

      def clear_attribute_cache!
        @attributes = nil
      end
      
      # Returns dtk component ids that are linked from this by link_def_type
      def get_connected_dtk_component_ids(link_def_type)
        ret = []
        # It is assumed that the dependencies have been added to @dtk_component
        unless dependencies = @dtk_component[:dependencies]
          Log.error("Unexpected that no dependencies in #{@dtk_componen.inspect}") 
          return ret
        end
        matching_deps = dependencies.select { |dep| (dep.link_def || {})[:link_type] == link_def_type }
        matching_deps.map { |dep| dep.satisfied_by_component_ids }.flatten(1)
      end

      private

      def ret_type(dtk_component)
        dtk_component.get_field?(:component_type).gsub('__', '::')
      end
    end
  end
end
