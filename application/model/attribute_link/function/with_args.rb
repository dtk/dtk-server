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
module DTK; class AttributeLink
  class Function
    class WithArgs < self
      r8_nested_require('with_args', 'function_info')

      def initialize(function_def, propagate_proc)
        super
        @function_info = FunctionInfo.create(function_def)
      end

      def self.with_args_link_function(base_fn, parse_info)
        outer_function = base_fn
        inner_expression = {
          function: {
            name: parse_info[:name],
            constants: parse_info[:constants]
          }
        }
        Composite.composite_link_function(outer_function, inner_expression)
      end

      def self.function_name?(function_def)
        if function_info = FunctionInfo.create?(function_def)
          function_info.name
        end
      end

      private

       def constants
         @function_info.constants()
       end
    end
  end
end; end