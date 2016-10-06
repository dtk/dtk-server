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
      require_relative('violation/sort_order')
      extend SortOrderClassMixin
      # above need to be before including the violation subclasses
      require_relative('violation/sub_classes')

      def table_form(opts = {})
        type_and_description(opts)
      end

      # must be overwritten
      def hash_form
        fail Error, "Missing method '#{self.class}#hash_form'"
      end

      # could be overwritten
      def self.type
        Aux.underscore(Aux.demodulize(to_s)).to_sym
      end

      # could be overwritten
      def self.impacted_by 
        []
      end

      private

      # must be overwritten
      def fix_text
        fail Error, "Missing method '#{self.class}#fix_text'"
      end

      def type 
        self.class.type
      end

      def attr_display_name(attr, print_level = :component)
        attr.print_form(Opts.new(level: print_level, convert_node_component: true))[:display_name]
      end

      # opts can have keys
      #  :attr
      #  :legal_values
      def attribute_info(opts = {})
        attr = opts[:attr] || @attr
        attr.update_object!(:data_type, :hidden)
         remove_nil_values(
            ref: attr_display_name(attr, @print_level),
            datatype: attr[:data_type],
            hidden: attr[:hidden],
            legal_values: opts[:legal_values]
         )
      end

      # opts can have keys
      #   :summary - Boolean
      def type_and_description(opts = {})
        { type: type, description: description(opts) }
      end

      def hash_form_multiple_attrs(attrs, attr_display_names, element_type)
        fix_hashes = []
        attrs.each_with_index do |attr, i|
          fix_hash =  {
            type: element_type,
            attribute: attribute_info(attr: attr),
            fix_text: fix_text(attr_display_names[i])
          }
          fix_hashes << fix_hash
        end
        type_and_description(summary: true).merge(fix_hashes: fix_hashes)
      end
      
      # opts can have keys
      #   :seed 
      def remove_nil_values(hash, opts = {})
        hash.inject(opts[:seed] || {}) { |h, (k, v)| v.nil? ? h : h.merge(k => v) }
      end
    end
  end
end
