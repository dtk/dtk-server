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
  class Service::Component
    class Attribute

      attr_reader :name, :value, :dtk_attribute
      # Argument dtk_attribute is of type DTK::Attribute
      def initialize(dtk_attribute)
        @dtk_attribute = dtk_attribute
        dtk_attribute.update_object!(:display_name, :attribute_value)
        @name =  dtk_attribute[:display_name]
        @value = dtk_attribute[:attribute_value]
      end

      def self.create_attributes_from_dtk_attributes(dtk_attributes)
        dtk_attributes.map { |dtk_attribute| new(dtk_attribute) }
      end

      private

      def ret_type(dtk_component)
        dtk_component.get_field?(:component_type).gsub('__', '::')
      end
    end
  end
end
