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
      class Attribute < Top
        definitions do
          target[:external_ref] = fn(:external_ref, source)
          target[:display_name] = fn(:display_name, source)
          (column_names(:attribute) - [:external_ref, :display_name]).each do |v|
            if_exists(source[v.to_s]) do
              target[v.to_sym] = source[v.to_s]
            end
          end
          if_exists(source['dependency']) do
            nested_definition :dependency, source['dependency']
          end
        end

        def self.relative_distinguished_name(source)
          source[:ref]
        end

        def self.display_name(source)
          source[:ref].split('/')
        end

        def self.external_ref(source)
          { type: 'attribute', path: source[:ref] }
        end
      end
    end
  end
end