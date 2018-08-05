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
  class ConfigAgent::Adapter::Component::DelegationAction::Inputs
    class Attribute
      def initialize(value_term, ndx_base_attributes)
        @value_term          = value_term
        @ndx_base_attributes = ndx_base_attributes
      end
      private :initialize

      def self.value(value_term, ndx_base_attributes)
        new(value_term, ndx_base_attributes).value
      end
      def value
        if self.value_term =~ /^[$]([a-zA-Z0-9\-_]+)$/
          attribute_name = $1
          attribute = self.ndx_base_attributes[attribute_name] || fail(ErrorUsage, "value term '#{value_term}' refers to an attribute that does not exist")
          attribute.attribute_value
        else
          fail Error, "value of form '#{self.value_term}' not treated yet"
        end
      end

      protected
   
      attr_reader :value_term, :ndx_base_attributes

    end
  end
end
