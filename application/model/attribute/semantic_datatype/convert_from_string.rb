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
  class Attribute::SemanticDatatype
    module ConvertFromString
      def self.convert_if_non_scalar_type(str_value, semantic_data_type, attribute_path)
        return str_value unless %w{array hash json}.include?(semantic_data_type)
        ret   = nil
        error = false
        in_json_form, value = in_form?(:json, str_value)
        if in_json_form
          ret = value
        elsif semantic_data_type == 'json'
          error = true
        else
          in_yaml_form, value = in_form?(:yaml, str_value)
          if in_yaml_form
            ret = value
          else
            error = true
          end
        end

        if error
          correct_form = (semantic_data_type == 'json' ? 'json form' : 'json or yaml form')
          fail ErrorUsage, "The attribute #{attribute_path} has data type #{semantic_data_type} and must be encoded in string having #{correct_form}"
        end
        ret
      end

      private

      # returns [parsed, value]
      def self.in_form?(format_type, str_value)
        value = parsed = nil
        value_or_error = Aux.convert_to_hash(str_value, format_type, do_not_raise: true)
        if value_or_error.kind_of?(ErrorUsage::Parsing)
          parsed = false
        else
          parsed =  true
          value = value_or_error
        end
        [parsed, value]
      end
    end
  end
end
