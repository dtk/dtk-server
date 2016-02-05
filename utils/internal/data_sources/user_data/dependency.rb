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
      class Dependency < Top
        definitions do
          [:display_name, :type, :search_pattern, :description, :severity].each do |k|
            target[k] = fn(k, source)
          end
        end

        def self.relative_distinguished_name(source)
          source[:ref]
        end

        def self.display_name(source)
          source['display_name']
        end

        def self.type(source)
          ret = source['type'] || ('component' if source['required_component'])
          fail Error.new('unexpected form for chef dependency') unless ret
          ret
        end

        def self.severity(source)
          source['severity'] || type(source) == 'component' ? 'warning' : 'error'
        end

        def self.search_pattern(source)
          return source['search_pattern'] if source['search_pattern']
          component = source['required_component']
          fail Error.new('unexpected form for userdata dependency') unless component
          XYZ::Constraints::Macro::RequiredComponent.search_pattern(component)
        end

        def self.description(source)
          return source['description'] if source['description']
          required_cmp = source['required_component']
          base_cmp = source['parent_display_name']
          fail Error.new('unexpected form for userdata dependency') unless required_cmp && base_cmp
          XYZ::Constraints::Macro::RequiredComponent.description(required_cmp, base_cmp)
        end
      end
    end
  end
end