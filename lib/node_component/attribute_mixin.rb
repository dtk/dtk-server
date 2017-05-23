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
  class NodeComponent
    module AttributeMixin
      # returns attribute object
      def attribute(attribute_name) 
        fail(Error, "Illegal attribute '#{attribute_name}' for component '#{component.display_name}'") unless ndx_attributes.has_key?(attribute_name)  
        ndx_attributes[attribute_name]
      end
      
      def attribute_value?(attribute_name) 
        attribute(attribute_name)[:attribute_value]
      end
      
      def attribute_value(attribute_name)
        attribute_value?(attribute_name) || fail(Error, "Unexpected that attribute '#{attribute_name}' is not set")
      end
      
      # returns [is_special_value, special_value] where if first is false then second should be ignored
      # this can be overwritten
      def update_if_dynamic_special_attribute!(_attribute)
        [false, nil]
      end
      
      def update_attribute!(attribute_name, attribute_value)
        attribute = attribute(attribute_name)
        attribute[:value_asserted] = attribute_value
        attribute[:value_derived]  = nil
        Attribute.update_and_propagate_attributes(attribute_model_handle, [attribute], add_state_changes: false, partial_value: false)
      end
      
      
      private
      
      attr_reader :ndx_attributes
      
      def attribute_name_value_hash
        ndx_attributes.inject({}) { |h, (name, attribute)| h.merge(name => attribute[:attribute_value]) }
      end
      
      def attribute_model_handle
        @attribute_model_handle ||= component.model_handle(:attribute)
      end
      
    end
  end
end
