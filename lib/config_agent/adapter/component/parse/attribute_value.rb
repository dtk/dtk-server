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
  class ConfigAgent::Adapter::Component::Parse
    class AttributeValue
      def initialize(value_term, name_ndx_values)
        @value_term      = value_term
        @name_ndx_values = name_ndx_values
      end
      private :initialize
      
      def self.value?(value_term, name_ndx_values)
        new(value_term, name_ndx_values).value
      end
      
      def self.value(value_term, name_ndx_values)
        new(value_term, name_ndx_values).value(required: true)
      end
      
      # opts can have keys:
      #   :required
      def value(opts = {})
        if self.value_term =~ /^[$]([a-zA-Z0-9\-_]+)$/
          attribute_name = $1
          value_when_variable(attribute_name, required: opts[:required])
        else
          fail Error, "value of form '#{self.value_term}' not treated yet"
        end
      end

      protected
   
      attr_reader :value_term, :name_ndx_values

      private

      # opts can have keys:
      #   :required
      def value_when_variable(attribute_name, opts = {})
        if self.name_ndx_values.has_key?(attribute_name)
          self.name_ndx_values[attribute_name]
        elsif opts[:required]
          fail ErrorUsage, "value term '#{self.value_term}' refers to an attribute that does not exist"
        else
          nil
        end
      end
      
    end
  end
end
