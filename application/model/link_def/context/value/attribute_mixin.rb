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
module DTK; class LinkDef::Context
  class Value
    module AttributeMixin
      def set_attribute_value!(attribute)
        @attribute = attribute
      end

      def value
        @attribute
      end

      def is_array?
        @attribute[:semantic_type_object].is_array?()
      end

      def node
        @node ||= ret_node()
      end

      def on_node_group?
        node().is_node_group?()
      end

      def node_group_cache
        ret = node()
        unless ret.is_node_group?()
          fail Error.new('Shoud not be called if not node group')
        end
        ret
      end
    end
  end
end; end