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
  class HashObject
    class AutoViv < self
      def [](x)
        result = frozen? ? (super if key?(x)) : super
        convert_type(result)
      end

      def recursive_freeze
        each_value { |el| el.recursive_freeze if el.respond_to?(:recursive_freeze) }
        freeze
      end

      def ArrayClass
        ArrayObject
      end

      def convert_type(string_literal)
        case string_literal
        when /^true$/i
          true
        when /^false$/i
          false
        else
          string_literal
        end
      end

      class << self
        # auto vivification trick from http://t-a-w.blogspot.com/2006/07/autovivification-in-ruby.html
        def create
          self.new { |h, k| h[k] = self.new(&h.default_proc) }
        end
      end
    end
  end
end