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
  module Propagate
    module Mixin
      def input_value
        @input_attr[:value_derived]
      end

      def input_semantic_type
        SemanticType.create_from_attribute(@input_attr)
      end

      def output_value(opts = {})
        if opts.key?(:inner_value)
          opts[:inner_value]
        else
          @output_attr[:value_asserted] || @output_attr[:value_derived]
        end
      end

      def output_semantic_type
        SemanticType.create_from_attribute(@output_attr)
      end
    end
  end
end; end