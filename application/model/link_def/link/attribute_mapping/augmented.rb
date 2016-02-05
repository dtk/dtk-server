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
module DTK; class LinkDef::Link
  class AttributeMapping
    # attribute mapping augmented with context
    class Augmented < Hash
      def initialize(attribute_mapping, input_attr, input_path, output_attr, output_path)
        super()
        @attribute_mapping = attribute_mapping
        merge!(input_id: input_attr.id, output_id: output_attr.id)
        merge!(input_path: input_path) if input_path
        merge!(output_path: output_path) if output_path
      end

      def parse_function_with_args?
        @attribute_mapping.parse_function_with_args?()
      end
    end
  end
end; end