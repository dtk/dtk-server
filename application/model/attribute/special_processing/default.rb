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
  class Attribute
    class SpecialProcessing
      class Default < self
        require_relative('default/group_cardinality')

        def self.handle_special_processing_attributes(existing_attributes, ndx_new_vals)
          existing_attributes.each do |attribute|
            next unless SPECIAL_PROCESSING_ATTRIBUTES.include?(attribute.display_name)
            # only special_processing on component attributes
            next unless component = attribute.get_component?
            
            if attribute_info = needs_special_processing?(attribute, component)
              new_val = ndx_new_vals[attribute[:id]]
              attribute_info[:proc].call(attribute, component, new_val)
            end
          end
        end
        
        def self.process(attribute, component, value)
          new(attribute, component, value).process
        end
        
        private
        
        attr_reader :attribute, :component, :new_val
        
        # returns attribute_info or nil
        def self.needs_special_processing?(attribute, component)
          attribute_info = SPECIAL_PROCESSING_INFO[attribute.display_name.to_sym]
          attribute_info if attribute_info[:component_types].include?(component[:component_type])
        end
        
        SPECIAL_PROCESSING_INFO = {
          cardinality: {
            component_types: ['ec2__node_group'],
            proc: lambda { |attribute, component, value| GroupCardinality.process(attribute, component, value) }
          }
        }
        SPECIAL_PROCESSING_ATTRIBUTES = SPECIAL_PROCESSING_INFO.keys.map(&:to_s)
        
      end
    end
  end
end
