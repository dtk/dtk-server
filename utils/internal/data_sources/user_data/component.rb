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
    class UserData
      class Component < Top
        definitions do
          target[:display_name] = source['ref']
          target[:basic_type] = fn(:basic_type, source)
          (column_names(:component) - [:display_name, :basic_type]).each do |v|
            if_exists(source[v.to_s]) do
              target[v.to_sym] = source[v.to_s]
            end
          end
          if_exists(source['attribute']) do
            nested_definition :attribute, source['attribute']
          end
          if_exists(source['dependency']) do
            nested_definition :dependency, fn(:dependency, source)
          end
        end
        def self.unique_keys(source)
          [source['qualified_ref']]
        end

        def self.dependency(source)
          dep = source['dependency']
          dep.inject({}) { |h, kv| h.merge(kv[0] => kv[1].merge('parent_display_name' => source['ref'])) }
        end

        def self.relative_distinguished_name(source)
          source['ref']
        end

        def self.basic_type(source)
          # TODO: assumes that user_data has all basic types specfic types
          return source['basic_type'] if source['basic_type']
          if source['specific_type']
            basic_type = ComponentTypeHierarchy.basic_type(source['specific_type'])
            basic_type && basic_type.to_s
          end
        end
      end
    end
  end
end