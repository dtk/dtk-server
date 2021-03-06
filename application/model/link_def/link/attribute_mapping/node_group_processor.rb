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
    # processes service node groups when needed
    class NodeGroupProcessor
      attr_reader :attribute_mapping, :input_path, :output_path
      def initialize(attribute_mapping, link_def_context, attr_and_path_info, _opts = {})
        @attribute_mapping = attribute_mapping
        @link_def_context = link_def_context
        info = attr_and_path_info # for succinctness
        @input_attr_obj = info[:input_attr_obj]
        @input_path = info[:input_path]
        @output_attr_obj = info[:output_attr_obj]
        @output_path = info[:output_path]
      end
      private :initialize
      def input_attr
        @input_attr_obj.value()
      end

      def output_attr
        @output_attr_obj.value()
      end

      # returns Array of Augmented (AttributeMapping) objects
      # clones component and their attributes from a node group if needed
      def self.aug_attr_mappings__clone_if_needed(attribute_mapping, link_def_context, attr_and_path_info, opts = {})
        new(attribute_mapping, link_def_context, attr_and_path_info, opts).aug_attr_mappings__clone_if_needed(opts)
      end

      def aug_attr_mappings__clone_if_needed(opts = {})
        ret = []
        input_attr = input_attr()
        port_link_id = opts[:port_link_idh] && opts[:port_link_idh].get_id()
        if cloning_node_group_members_needed?()
          node_group_attrs = @output_attr_obj.get_ng_member_attributes__clone_if_needed(opts)
          node_group_attrs.each do |output_attr|
            ret << ret_single_link(input_attr, output_attr, port_link_id)
          end
        else
          ret << ret_single_link(input_attr, output_attr(), port_link_id)
        end
        ret
      end

      private

      def ret_single_link(input_attr, output_attr, port_link_id = nil)
        ret = Augmented.new(@attribute_mapping, input_attr, @input_path, output_attr, @output_path)
        if port_link_id
          ret.merge!(port_link_id: port_link_id)
        end
        ret
      end

      def cloning_node_group_members_needed?
        num_ngs = [@input_attr_obj.node, @output_attr_obj.node].inject(0) { |r, n| r + (n.is_node_group? ? 1 : 0) }
        if num_ngs == 0
          return nil
        elsif num_ngs == 2
          fail ErrorUsage.new('Not treating links between components that are both on node groups')
        end
        # determine if this manifests as single of multiple links; if single link just pass nil
        # when this is called there is one node group and one node
        return nil if @input_attr_obj.on_node_group?()

        # if reach here @output_attr_obj.on_node_group?
        if @output_attr_obj.is_array?() && @output_path.nil?
          fail ErrorUsage.new("Not treating attribute mappings from an array attribute on a node group (#{@output_attr_obj.pp_form()})")
        end
        if @output_attr_obj.is_node_attribute?() && !@input_attr_obj.is_array?()
          fail ErrorUsage.new("Node attributes on node groups (#{@output_attr_obj.pp_form()}) must connect to an array attribute, not '#{@input_attr_obj.pp_form()}'")
        end
        true
      end
    end
  end
end; end