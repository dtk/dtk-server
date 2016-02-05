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
    class Composite < WithArgs
      def initialize(function_def, propagate_proc)
        super
        # need to reify constants
        reify_constant!(:outer_function, propagate_proc)
        reify_constant!(:inner_expression, propagate_proc)
      end

      def self.composite_link_function(outer_function, inner_expression)
        {
          function: {
            name: :composite,
            constants: {
              outer_function: outer_function,
              inner_expression: inner_expression
            }
          }
        }
      end

      def internal_hash_form(opts = {})
        unless opts.empty?
          fail Error.new('Opts should be empty')
        end
        inner_value = inner_expression.value()
        outer_function.internal_hash_form(inner_value: inner_value)
      end

      def value(_opts = {})
        inner_value = inner_expression.value()
        outer_function.value(inner_value: inner_value)
      end

      private

      def reify_constant!(constant_name, propagate_proc)
        nested_function_def = constants[constant_name]
        nested_fn_name = self.class.function_name(nested_function_def)
        nested_klass = self.class.klass(nested_fn_name)
        constants[constant_name] = nested_klass.new(nested_function_def, propagate_proc)
      end

      def inner_expression
        constants[:inner_expression]
      end

      def outer_function
        constants[:outer_function]
      end
    end
  end
end; end