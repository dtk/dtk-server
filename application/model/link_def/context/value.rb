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
  class LinkDef::Context
    class Value
      r8_nested_require('value', 'component')
      r8_nested_require('value', 'attribute_mixin') # must be before component_attribute and node_attribute
      r8_nested_require('value', 'component_attribute')
      r8_nested_require('value', 'node_attribute')
      attr_reader :component
      def initialize(component_ref)
        @component_ref = component_ref
        @component = nil
      end

      def self.create(term, opts = {})
        case term[:type].to_sym
         when :component
          Component.new(term)
         when :component_attribute
          ComponentAttribute.new(term, opts)
         when :node_attribute
          NodeAttribute.new(term, opts)
         else
          Log.error("unexpected type #{type}")
          nil
        end
      end

      # can be overwritten
      def is_node_attribute?
        false
      end

      # can be overwritten
      def get_ng_member_attributes__clone_if_needed(_opts = {})
        []
      end

      def set_component_remote_and_local_value!(link, cmp_mappings)
        return if @component_ref.nil? #would fire if this is a NodeAttribute
        if @component_ref == link[:local_component_type]
          @component = cmp_mappings[:local]
        elsif @component_ref == link[:remote_component_type]
          @component = cmp_mappings[:remote]
        end
      end

      def set_component_value!(component)
        @component = component
      end

      # no op unless overwritetn
      def update_component_attr_index!(_component_attr_index)
      end
      # overwritten
      def value
      end
    end
  end
end