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
      class Node < Top
        definitions do
          target[:display_name] = fn(:display_name, source)
          %w(tag disk_size ui).each do |key|
            target[key.to_sym] = source[key]
          end
        end
         class << self
            def unique_keys(source)
              [source['qualified_ref']]
            end

           def relative_distinguished_name(source)
             source['ref']
           end

           def display_name(source)
             source['display_name'] || source['ref']
           end
         end
      end
    end
  end
end