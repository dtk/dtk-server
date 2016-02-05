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
      class Node < Top
        definitions do
          target[:display_name] = source['node_name']
          target[:tag] = if_unset(source['node_display_name'])
          if_exists(source['lsb']) do
            target['os'] = fn(lambda { |x| x ? x.gsub(/"/, '') : nil }, source['lsb']['description'])
          end
          # TODO: whether bloew should be component_instance instead
          nested_definition :component, source['components']
        end
        class << self
          def relative_distinguished_name(source)
            source['node_name']
          end
        end
      end
    end
  end
end