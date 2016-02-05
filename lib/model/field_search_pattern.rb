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
# TODO: see if can collapse or better integrate with dataset_from_search_pattern.rb
module XYZ
  module FieldSearchPatternInstanceMixin
    class FieldSearchPattern
      def initialize(model_name, field_set_class)
        @col_basic_types = ColumnTypeCache[model_name] ||= field_set_class.scalar_cols_with_types(model_name).inject({}) { |h, nt| h.merge(nt[0] => BasicTypeMapping[nt[1]]) }
      end

      def ret_where_clause_for_search_string(name_value_pairs)
        ret = nil
        name_value_pairs.each do |name_x, value|
          name = name_x.to_sym
          # ignore if empty
          next if (value && value.empty?)
          # ignore unless column has a basic type
          basic_type = @col_basic_types[name]
          next unless basic_type
          new_el =
            if value.nil? || value == 'UNSET'
              { name => nil }
            else
              case basic_type
               when :string
                SQL::WhereCondition.like(name, "#{value}%")
               when :numeric
                process_numeric(name, value)
               when :boolean
                { name => (value == 1 || value == '1') ? true : false }
              end
          end
          ret = SQL.and(ret, new_el)
        end
        ret
      end

      private

      def process_numeric(name, value)
        # TODO: may encapsulate undet SQL class
        if value =~ /^<=(.+)$/
          name.to_s.lit <= Regexp.last_match(1)
        elsif value =~ /^>=(.+)$/
          name.to_s.lit >= Regexp.last_match(1)
        elsif value =~ /^<(.+)$/
          name.to_s.lit < Regexp.last_match(1)
        elsif value =~ /^>(.+)$/
          name.to_s.lit > Regexp.last_match(1)
        else
          { name => value }
        end
      end

      ColumnTypeCache = {}
      BasicTypeMapping = {
        string: :string,
        text: :string,
        varchar: :string,
        bigint: :numeric,
        integer: :numeric,
        int: :numeric,
        numeric: :numeric,
        boolean: :boolen
      }
    end
  end
end