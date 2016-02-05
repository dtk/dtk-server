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
  class DocGenerator
    class Domain
      r8_nested_require('domain', 'active_support_instance_variables')
      r8_nested_require('domain', 'input')
      r8_nested_require('domain', 'component_module')
      r8_nested_require('domain', 'service_module')
      
      extend ActiveSupportInstanceVariablesMixin
      
      def self.normalize_top(parsed_dsl)
        if parsed_dsl.kind_of?(ParsedDSL::ComponentModule)
          ComponentModule.normalize_top(parsed_dsl)
        elsif parsed_dsl.kind_of?(ParsedDSL::ServiceModule)
          ServiceModule.normalize_top(parsed_dsl)
        else
          fail Error, "Normalize dsl object of type '#{parsed_dsl.class}' is not treated"
        end
      end
      
      def self.normalize(*args)
        active_support_instance_values(new(*args))
      end

      attr_reader :name

      private
      
      def base(input)
        @name        = input.scalar(:display_name)
        @description = input.scalar(:description)
      end

      def raw_input(obj)
        self.class::Input.raw_input(obj)
      end
    end
  end
end