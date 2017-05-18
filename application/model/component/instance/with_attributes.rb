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
# There might be anumber of ways to encode this; such as actually adding to schema; one direction looking towards is having effectively foreign
# keys where for example the linux user can point to  a linux user table.
# In approach below teher wil be a numeric key genearted which is a handle on object; sometimes an attribute may be key, but not sure always
module DTK
  class Component::Instance
    class WithAttributes
      attr_reader :component, :attributes
      def initialize(component, attributes)
        @component  = component
        @attributes = attributes
      end
      private :initialize

      def self.components_with_attributes(components)
        ndx_attributes = ndx_attributes(components)
        components.map do |component| 
          unless attributes = ndx_attributes[component.id]
            Log.error("Unexpected that ndx_attributes(components)[component.id] is nil")
            attributes = []
          end

          new(component, attributes) 
        end
      end

      def attribute(name)
        @ndx_attributes[name] || fail(Error, "Unexpected that attribute '#{name}' does not exist") 
      end

      private

      ATTRIBUTE_COLS = [:id, :group_id, :display_name, :attribute_value, :component_component_id]

      def self.ndx_attributes(components)
        ndx_attributes = {}
        Component::Instance.get_attributes(components.map(&:id_handle), cols: ATTRIBUTE_COLS).each do |attribute|
          (ndx_attributes[attribute[:component_component_id]] ||= []) << attribute
        end
        ndx_attributes
      end

    end
  end
end
