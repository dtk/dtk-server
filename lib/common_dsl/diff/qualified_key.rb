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
  class CommonDSL::Diff
    class QualifiedKey 
      def initialize(elements_to_copy = [])
        @key_elements = copy(elements_to_copy)
      end

      def create_with_new_element?(type, key)
        new_key_elements = key.nil? ? @key_elements : @key_elements + [{type: type, key: key }]
        self.class.new(new_key_elements)
      end

      QUALIFIED_KEY_DELIM = '/'
      def print_form
        @key_elements.inject('') do |s, el|
          s.empty? ? el[:key] : s + QUALIFIED_KEY_DELIM + el[:key]
        end
      end

      private

      def copy(key_elements)
        ret = []
        key_elements.each { |el| ret << { type: el[:type], key: el[:key] } }
        ret
      end
      
    end
  end
end
