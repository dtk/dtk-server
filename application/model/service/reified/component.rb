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
  module Service::Reified
    # Reified::Component is an abstract class that roots reified service components
    class Component
      r8_nested_require('component', 'with_service_component')

      def initialize
        # These elemnets of this hash get set on demand
        @cached_attributes = {}
        @cached_connected_components = {} #cache connected objects
      end

      def clear_attribute_cache!
        @cached_attributes = {}
      end

      def use_and_set_attribute_cache(attribute_name, &body)
        @cached_attributes[attribute_name] ||= yield
      end

      def use_and_set_connected_component_cache(conn_component_type, &body)
        @cached_connected_components[conn_component_type] ||= yield
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
        self.class.legal_attributes.include?(attribute_method)
      end

      def self.legal_attributes
        Log.error("Abstract method that should be overwritten for class '#{self}'")
        []
      end
    end
  end
end
