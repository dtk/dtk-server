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
module DTK; module CommonDSL::Generate
  class ContentInput 
    class Assembly
      class Component < ContentInput::Hash
        require_relative('component/diff')
        require_relative('component/attribute')

        def initialize(aug_component)
          super()
          @aug_component = aug_component
        end
        private :initialize

        def self.generate_content_input(aug_components)
          aug_components.inject(ContentInput::Hash.new) do |h, aug_component|
            h.merge(component_name(aug_component) => new(aug_component).generate_content_input!)
          end
        end
        
        def generate_content_input!
          set_id_handle(@aug_component)
          attributes = @aug_component[:attributes] || []
          set?(:Attributes, Attribute.generate_content_input?(:component, attributes, component: @aug_component)) unless attributes.empty?
          # TODO: add component links
          if tags = tags?
            add_tags!(tags)
          end
          self
        end

        # For diffs
        def diff?(component_parse, key)
          aggregate_diffs?(key) do |diff_set|
            diff_set.add? Attribute.diff_set(val(:Attributes), component_parse.val(:Attributes))
            # TODO: need to add diffs on all subobjects
          end
        end

        def self.diff_set(nodes_gen, nodes_parse)
          diff_set_from_hashes(nodes_gen, nodes_parse)
        end

        private

        def self.component_name(aug_component)
          aug_component.display_name_print_form(without_version: true)
        end
        
        def tags?
          ret = []
          # mark hidden any node_property component
          ret << :hidden if node_property_component_types.include?(@aug_component[:component_type])
          ret.empty? ? nil : ret
        end

        def node_property_component_types
          @@node_property_component_types ||= CommandAndControl.node_property_component_types
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
          cols: node_scalar_cols + [:components_and_their_attrs],
          filter: [:oneof, :id, node_ids]
        }

        node_cmp_attr_rows = Model.get_objs(node_mh, sp_hash, keep_ref_cols: true)
        if node_cmp_attr_rows.empty?
          fail ErrorUsage.new('No components in the nodes being grouped to be an assembly template')
        end
        cmp_scalar_cols = node_cmp_attr_rows.first[:component].keys - [:components_and_their_attrs]
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
