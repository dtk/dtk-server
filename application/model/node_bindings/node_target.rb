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
  class NodeBindings
    class NodeTarget
      r8_nested_require('node_target', 'assembly_node')
      r8_nested_require('node_target', 'image')

      attr_reader :type
      def initialize(type)
        @type = type
      end

      def hash_form
        { type: type().to_s }
      end

      def self.parse_and_reify(parse_input)
        AssemblyNode.parse_and_reify(parse_input, donot_raise_error: true) ||
        Image.parse_and_reify(parse_input, donot_raise_error: true) ||
        fail(parse_input.error('Node Target has illegal form: ?input'))
      end

      def match_or_create_node?(_target)
        :match
      end

      # This can be overwritten
      def node_external_ref?
        nil
      end
    end
  end
end
