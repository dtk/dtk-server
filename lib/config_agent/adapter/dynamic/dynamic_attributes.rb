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
  class ConfigAgent::Adapter::Dynamic
    module DynamicAttributes
      module Mixin
        def get_dynamic_attributes(payload, action)
          if dyn_attrs = (payload[:data] || {})['dynamic_attributes']
            DynamicAttributes.parse_dynamic_attributes(dyn_attrs, action)
          else
            []
          end
        end 

        def dynamic_attribute_name_raw_value_hash(payload)
          (payload[:data] || {})['dynamic_attributes'] || {}
        end
      end      
      
      def self.parse_dynamic_attributes(dyn_attrs, action)
        ret = []
        dyn_attrs.each_pair do |attr_name, raw_attr_val|
          attribute = action.find_matching_attribute?(attr_name)
          if attribute && attribute.get_field?(:dynamic)
            val = attribute.use_attribute_datatype_to_convert(raw_attr_val)
            ret << action.dynamic_attribute_return_form(attribute.id, val)
          end
        end
        ret
      end

    end
  end
end
