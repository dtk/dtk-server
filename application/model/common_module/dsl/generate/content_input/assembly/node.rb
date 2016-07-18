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
module DTK; module CommonModule::DSL::Generate
  class ContentInput 
    class Assembly
      class Node < ContentInput::Hash
        def self.generate_content_input(assembly_instance)
          ret = ContentInput::Array.new
          get_augmented_nodes(assembly_instance).each { |aug_node| ret << new.generate_content_input!(aug_node) }
          ret
        end
        
        def generate_content_input!(aug_node)
          aug_components = aug_node[:components] || []
          attributes = aug_node[:attributes] || []
          # :is_assembly_wide_node just used intentall; so not using 'set' method
          self[:is_assembly_wide_node] = true if aug_node.is_assembly_wide_node?
          
          set(:Name, aug_node.display_name)
          set(:Attributes, Attribute.generate_content_input(attributes))  unless attributes.empty?
          set(:Components, Component.generate_content_input(aug_components)) unless aug_components.empty?
          self
        end

        private
        
        def self.get_augmented_nodes(assembly_instance)
          ndx_nodes = assembly_instance.get_nodes.inject({}) { |h, r| h.merge(r.id => r) }
          add_node_level_attributes!(ndx_nodes)
          add_augmented_components!(ndx_nodes)
          # TODO: add all oher needed content, i.e., links
          ndx_nodes.values
        end
        
        def self.add_node_level_attributes!(ndx_nodes)
          node_idhs = ndx_nodes.values.reject { |node| node.is_assembly_wide_node? }.map(&:id_handle)
          unless node_idhs.empty?
            DTK::Node.get_node_level_assembly_template_attributes(node_idhs).each do |r|
              node_id = r[:node_node_id]
              (ndx_nodes[node_id][:attributes] ||= []) << r
            end
          end
        end

        def self.add_augmented_components!(ndx_nodes)
          DTK::Node::Instance.add_augmented_components!(ndx_nodes)
        end
        
      end
    end
  end
end; end

=begin
      def add_content_for_clone!
        node_idhs = assembly_instance.get_nodes().map(&:id_handle)
        if node_idhs.empty?
          fail ErrorUsage.new("Cannot find any nodes associated with assembly (#{assembly_instance.get_field?(:display_name)})")
        end

        # 1) get a content object, 2) modify, and 3) persist
        port_links, dangling_links = Node.get_conn_port_links(node_idhs)
        # TODO: raise error to user if dangling link
        Log.error("dangling links #{dangling_links.inspect}") unless dangling_links.empty?

        task_templates = assembly_instance.get_task_templates(serialized_form: true)

        node_scalar_cols = FactoryObject::CommonCols + [:type, :node_binding_rs_id]
        node_mh = node_idhs.first.createMH()
        node_ids = node_idhs.map(&:get_id)

        # get assembly-level attributes
        assembly_level_attrs = assembly_instance.get_assembly_level_attributes().reject do |a|
          a[:attribute_value].nil?
        end

        # get node-level attributes
        ndx_node_level_attrs = {}
        Node.get_node_level_assembly_template_attributes(node_idhs).each do |r|
          (ndx_node_level_attrs[r[:node_node_id]] ||= []) << r
        end

        # get contained ports
        sp_hash = {
          cols: [:id, :display_name, :ports_for_clone],
          filter: [:oneof, :id, node_ids]
        }
        @ndx_ports = {}
        node_port_mapping = {}
        Model.get_objs(node_mh, sp_hash, keep_ref_cols: true).each do |r|
          port = r[:port].merge(link_def: r[:link_def])
          (node_port_mapping[r[:id]] ||= []) << port
          @ndx_ports[port[:id]] = port
        end

        # get contained components-non-default attribute candidates
        sp_hash = {
          cols: node_scalar_cols + [:cmps_and_non_default_attr_candidates],
          filter: [:oneof, :id, node_ids]
        }

        node_cmp_attr_rows = Model.get_objs(node_mh, sp_hash, keep_ref_cols: true)
        if node_cmp_attr_rows.empty?
          fail ErrorUsage.new('No components in the nodes being grouped to be an assembly template')
        end
        cmp_scalar_cols = node_cmp_attr_rows.first[:component].keys - [:non_default_attr_candidate]
        @ndx_nodes = {}
        node_cmp_attr_rows.each do |r|
          node_id = r[:id]
          @ndx_nodes[node_id] ||=
            r.hash_subset(*node_scalar_cols).merge(
              components: [],
              ports: node_port_mapping[node_id],
              attributes: ndx_node_level_attrs[node_id]
            )
          cmps = @ndx_nodes[node_id][:components]
          cmp_id = r[:component][:id]
          unless matching_cmp = cmps.find { |cmp| cmp[:id] == cmp_id }
            matching_cmp = r[:component].hash_subset(*cmp_scalar_cols).merge(non_default_attributes: [])
            cmps << matching_cmp
          end
          if attr_cand = r[:non_default_attr_candidate]
            if non_default_attr = NonDefaultAttribute.isa?(attr_cand, matching_cmp)
              matching_cmp[:non_default_attributes] << non_default_attr
            end
          end
        end
        update_hash = {
          nodes:                     @ndx_nodes.values,
          port_links:                port_links,
          assembly_level_attributes: assembly_level_attrs,
          task_templates:            task_templates
        }
        merge!(update_hash)
        self
      end
=end
