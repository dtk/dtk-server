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
module XYZ
  module DSNormalizer
    class Chef
      class ComponentInstance < Top
        definitions do
          target[:type] = 'instance'
          target[:basic_type] = fn(:basic_type, source['basic_type'])
          target[:component_type] = fn(:component_type, source)
          target[:display_name] = fn(:display_name, source)
          target[:description] = source['description']
          target[:external_ref] = fn(:external_ref, source['recipe_name'], source['node_name'])

          nested_definition :attribute, source['attributes']
        end

        class << self
          def unique_keys(source)
            [:instance, source['normalized_recipe_name']]
          end

          def relative_distinguished_name(source)
            source['normalized_recipe_name']
          end

          def display_name(source)
            source['normalized_recipe_name']
          end

          def component_type(source)
            source['normalized_recipe_name']
          end

          def external_ref(recipe_name, node_name)
            { 'type' => 'chef_recipe_instance', 'recipe_name' => recipe_name, 'node_name' => node_name }
          end

          def basic_type(basic_type)
            return basic_type unless basic_type.is_a?(Hash)
            basic_type.keys.first
          end
        end
      end
    end
  end
end