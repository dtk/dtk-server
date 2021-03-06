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
module DTK; class Attribute
  class Pattern; class Type
    class NodeLevel < self
      include CommonNodeComponentLevel

      def type
        :node_level
      end

      def match_attribute_mapping_endpoint?(am_endpoint)
        am_endpoint[:type] == 'node_attribute' &&
          attr_name_normalize(am_endpoint[:attribute_name]) == attr_name_normalize(attribute_name())
      end

      def am_serialized_form
        "#{local_or_remote()}_node.#{attribute_name()}"
      end

      def set_parent_and_attributes!(parent_idh, opts = {})
        ret = self
        @attribute_stacks = []
        ndx_nodes = ret_matching_nodes(parent_idh).inject({}) { |h, r| h.merge(r[:id] => r) }
        return ret if ndx_nodes.empty?

        pattern =~ /^node[^\/]*\/(attribute.+$)/
        attr_fragment = attr_name_special_processing(Regexp.last_match(1))
        attrs = ret_matching_attributes(:node, ndx_nodes.values.map(&:id_handle), attr_fragment)
        if attrs.empty? && create_this_type?(opts)
          @created = true
          set_attribute_properties!(opts[:attribute_properties] || {})
          attrs = create_attributes(ndx_nodes.values)
        end

        @attribute_stacks = attrs.map do |attr|
          {
            attribute: attr,
            node: ndx_nodes[attr[:node_node_id]]
          }
        end
        ret
      end

      def set_component_instance!(component_type)
        cmp_fragment = Term.canonical_form(:component, component_type)
        matching_cmps = ret_matching_components([node()], cmp_fragment)
        if matching_cmps.empty?
          fail ErrorUsage.new("Illegal component reference (#{component_type})")
        elsif matching_cmps.size > 1
          fail Error.new('Unexpected that ret_matching_components wil return more than 1 match')
        end
        attribute_stack()[:component] = matching_cmps.first
      end

      attr_writer :local_or_remote

      private

      def pattern_attribute_fragment
        pattern() =~ AttrRegexp
        Regexp.last_match(1)
      end
      AttrRegexp = /^node[^\/]*\/(attribute.+$)/

      def local_or_remote
        unless @local_or_remote
          fail Error.new('local_or_remote() is caleld when @local_or_remote not set')
        end
        @local_or_remote
      end

      def attr_name_normalize(attr_name)
        if attr_name == 'host_addresses_ipv4'
          'host_address'
        else
          attr_name
        end
      end

      def attr_name_special_processing(attr_fragment)
        # TODO: make this obtained from shared logic
        if attr_fragment == Pattern::Term.canonical_form(:attribute, 'host_address')
          Pattern::Term.canonical_form(:attribute, 'host_addresses_ipv4')
        else
          attr_fragment
        end
      end
    end
  end; end
end; end