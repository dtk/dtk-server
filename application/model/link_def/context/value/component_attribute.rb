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
    class ComponentAttribute < self
      include AttributeMixin
      attr_reader :attribute_ref
      def initialize(term, opts = {})
        super(term[:component_type])
        @attribute_ref = term[:attribute_name]
        @node_mappings =  opts[:node_mappings]
      end

      def pp_form
        attr =  @attribute.get_field?(:display_name)
        cmp = @component.get_field?(:display_name)
        node = node().get_field?(:node)
        "#{node}/#{cmp}/#{attr}"
      end

      def update_component_attr_index!(component_attr_index)
        p = component_attr_index[@component_ref] ||= []
        p << { attribute_name: @attribute_ref, value_object: self }
      end

      # this should only be called on a node group
      # it returns the associated attributes on the node goup members
      def get_ng_member_attributes__clone_if_needed(opts = {})
        node_group_attrs = service_node_group_cache().get_component_attributes(@component, opts)
        attr_name = @attribute.get_field?(:display_name)
        node_group_attrs.select { |a| a[:display_name] == attr_name }
      end

      private

      def ret_node
        node_id = @component[:node_node_id]
          @node_mappings.values.find { |n| n[:id] == node_id }
      end
    end
  end
end; end