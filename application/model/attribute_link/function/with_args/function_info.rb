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
  class Function::WithArgs
    class FunctionInfo
      attr_reader :name, :constants
      def initialize(name, constants_hash)
        @name = name.to_sym
        @constants = Constants.new(constants_hash)
      end

      def self.create(function_def)
        unless ret = create?(function_def)
          fail Error.new("Error creating (#{function_def.inspect})")
        end
        ret
      end
      def self.create?(function_def)
        if function_def.is_a?(Hash) && function_def.key?(:function)
          fn_info_hash = function_def[:function]
          unless fn_info_hash && fn_info_hash.key?(:name)
            fail(Error.new("Function def has illegal form: #{function_def.inspect}"))
          end
          new(fn_info_hash[:name], fn_info_hash[:constants] || {})
        end
      end

      class Constants < Hash
        def initialize(hash)
          super()
          replace(hash)
        end

        def [](k)
          unless key?(k)
            fail Error.new("New constant (#{k}) found")
          end
          super
        end
      end
    end
  end
end; end