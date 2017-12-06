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
  class CommonModule::Import::ServiceModule
    module Assembly
      module Attributes
        def self.db_update_hash(parsed_attributes, opts = {})
          parsed_attributes.inject(DBUpdateHash.new) do |h, (attr_name, parsed_attribute)|
            attr_content = nil
            attr_info = parsed_attribute.val(:Value)
            if opts[:assembly_attributes]
              raise_error_if_ill_formed_assembly_attribute(attr_name, attr_info)
              attr_content = {
                'display_name'   => attr_name,
                'value_asserted' => attr_info['default'],
                'data_type'      => attr_info['type'],
                'required'       => attr_info['required'],
                'link_to'        => attr_info['links_to'],
                'link_from'      => attr_info['links_from']
              }
            else
              attr_content = {
                'display_name'   => attr_name,
                'value_asserted' => attr_info,
                'data_type'      => Attribute::Datatype.datatype_from_ruby_object(attr_info)
              }
            end
            h.merge(attr_name => attr_content)
          end
        end

        def self.raise_error_if_ill_formed_assembly_attribute(attr_name, attr_info)
          unless attr_info and (attr_info['links_to'] or attr_info['links_from'])
            fail ErrorUsage, "Parsing error: Assembly attribute '#{attr_name}' must have key 'links_to' or 'links_from'"
          end
        end

      end
    end
  end
end
