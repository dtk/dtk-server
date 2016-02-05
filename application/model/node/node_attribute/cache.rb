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
module DTK; class Node
  class NodeAttribute
    module Cache
      def self.attr_is_set?(node, name)
        (node[CacheKeyOnNode] || {}).key?(name.to_sym)
      end
      def self.get(node, name)
        (node[CacheKeyOnNode] || {})[name.to_sym]
      end
      def self.set!(node, raw_val, field_info)
        name = field_info[:name]
        semantic_data_type = field_info[:semantic_type]
        val =
          if raw_val && semantic_data_type
            Attribute::SemanticDatatype.convert_to_internal_form(semantic_data_type, raw_val)
          else
            raw_val
          end
        (node[CacheKeyOnNode] ||= {})[name.to_sym] = val
      end
      CacheKeyOnNode = :attribute_value_cache
    end
  end
end; end