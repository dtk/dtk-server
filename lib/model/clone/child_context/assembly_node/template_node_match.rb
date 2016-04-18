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
module DTK; class Clone::ChildContext::AssemblyNode
  class TemplateNodeMatch < Hash
    def initialize(hash)
      super()
      replace(hash)
    end
    private :initialize

    def self.create__when_creating_node(parent, node, node_template)
      instance_type = node.is_assembly_wide_node?() ? node_class(node).assembly_wide : node_class(node).staged
      hash = {
        instance_type: instance_type,
        node_stub_idh: node.id_handle,
        instance_display_name: node[:display_name],
        instance_ref: instance_ref(parent, node[:display_name]),
        node_template_idh: node_template.id_handle()
      }
      new(hash)
    end

    def self.create__when_match(parent, node, target_ref, extra_fields = {})
      hash = {
        instance_type: node_class(node).instance,
        node_stub_idh: node.id_handle,
        instance_display_name: node[:display_name],
        instance_ref: instance_ref(parent, node[:display_name]),
        node_template_idh: target_ref.id_handle(),
        donot_clone: [:attribute]
      }
      hash.merge!(extra_fields) unless extra_fields.empty?
      new(hash)
    end

    # indexed by instance display name
    # returns ndx_matches, ndx_mapping_rows
    def self.ndx_mapping_info(matches)
      ndx_matches = {}
      ndx_mapping_rows = matches.inject({}) do |h, m|
        display_name = m[:instance_display_name]
        ndx_matches.merge!(display_name => m)
        node_template_id = m[:node_template_idh].get_id()
        el = {
          type: m[:instance_type],
          ancestor_id: m[:node_stub_idh].get_id(),
          canonical_template_node_id: node_template_id,
          node_template_id: node_template_id,
          display_name: display_name,
          ref: m[:instance_ref]
        }
        h.merge(display_name => el)
      end
      [ndx_matches, ndx_mapping_rows]
    end

    private

    def self.node_class(node)
      node.is_node_group?() ? Node::Type::NodeGroup : Node::Type::Node
    end

    def self.instance_ref(parent, node_ref_part)
      "assembly--#{parent[:assembly_obj_info][:display_name]}--#{node_ref_part}"
    end
  end
end; end              