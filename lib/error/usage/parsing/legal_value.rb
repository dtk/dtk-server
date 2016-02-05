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
module DTK; class ErrorUsage
  class Parsing
    class LegalValue
      # either input_form or legal_values_block will be nil
      def self.reify(input_form, &legal_values_block)
        if legal_values_block
          class_eval(&legal_values_block)
        elsif input_form.is_a?(LegalValue)
          input_form
        elsif input_form.is_a?(Class)
          Klass.new(input_form)
        else
          fail Error.new("Legal value type's class (#{input_form.class}) is not supported")
        end
      end

      # methods that can be evalued in legal_values_block
      def self.HashWithKey(*keys)
        HashWithKey.new(keys)
      end
      def self.HashWithSingleKey(*keys)
        HashWithSingleKey.new(keys)
      end

      class Klass < self
        def initialize(klass)
          @klass = klass
        end

        def matches?(object)
          object.is_a?(@klass)
        end

        def print_form
          @klass.to_s
        end
      end
      class HashWithKey
        def initialize(keys)
          @keys = Array(keys).map(&:to_s)
        end

        def matches?(object)
          object.is_a?(Hash) && !!object.keys.find { |k| @keys.include?(k.to_s) }
        end

        def print_form
          "HashWithKey(#{@keys.join(',')})"
        end
      end
      class HashWithSingleKey
        def initialize(keys)
          @keys = Array(keys).map(&:to_s)
        end

        def matches?(object)
          object.is_a?(Hash) && object.size == 1 && @keys.include?(object.keys.first.to_s)
        end

        def print_form
          "HashWithSingleKey(#{@keys.join(',')})"
        end
      end
    end
  end
end; end