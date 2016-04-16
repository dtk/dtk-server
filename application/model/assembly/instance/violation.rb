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
  class Assembly::Instance
    class Violation
      r8_nested_require('violation', 'sort_order')
      extend SortOrderClassMixin
      # above need to be before including the violation subclasses
      r8_nested_require('violation', 'sub_classes')

      def table_form
        type_and_display
      end

      # must be overwritten
      def hash_form
        fail Error, "Missing method '#{self.class}#hash_form'"
      end

      # could be overwritten
      def self.type
        Aux.underscore(Aux.demodulize(self.class.to_s)).to_sym
      end

      # could be overwritten
      def self.impacted_by 
        []
      end

      private

      def type 
        self.class.type
      end

      def attr_display_name(attr, print_level = :component)
        attr.print_form(Opts.new(level: print_level, convert_node_component: true))[:display_name]
      end

      def hash_form_aux(hash)
        hash.inject(type_and_display.merge(fix_text: fix_text)) do |h, (k, v)| 
          # This will remove nil values from hash
          v.nil? ? h : h.merge(k => v)
        end
      end

      def attribute_info
        @attr.update_object!(:data_type, :hidden)
        { 
          attribute: {
            ref: attr_display_name(@attr, @print_level),
            datatype: @attr[:data_type],
            hidden: @attr[:hidden]
          }
        }
      end

      def type_and_display
        { type: type, description: description }
      end

      # must be overwritten
      def fix_text
        fail Error, "Missing method '#{self.class}#fix_text'"
      end
    end
  end
end
