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
module DTK; class ServiceModule; class AssemblyExport
  module FoldIntoExisting
    class AssemblySectionProc
      attr_reader :raw_array

      def initialize(raw_content)
        @raw_content = raw_content
        @existing_hash_content = (YAML.load(raw_content)||{})['assembly']
      end

      def parse_and_order_assembly_hash(assembly_hash)
        new_cmps_hash    = {}
        new_nodes_hash   = {}
        parsed_cmps      = []
        parsed_nodes     = {}
        new_hash_content = {}

        assembly_cmps  = assembly_hash[:assembly][:components]||[]
        assembly_nodes = assembly_hash[:assembly][:nodes]||{}
        assembly_attrs = assembly_hash[:assembly][:attributes]||{}

        @existing_hash_content.each do |section_name, section_content|
          case section_name
           when 'components'
            parsed_cmps = parse_components(assembly_cmps, section_content)
            new_hash_content.merge!('components' => parsed_cmps)
           when 'nodes'
            parsed_nodes = parse_nodes(assembly_nodes, section_content)
            new_hash_content.merge!('nodes' => parsed_nodes)
           when 'attributes'
            parsed_attrs = parse_attributes(assembly_attrs, section_content)
            new_hash_content.merge!('attributes' => parsed_attrs)
           else
            p "Unhandled section #{section_name}!"
          end
        end

        new_hash_content.merge!('components' => assembly_cmps) if !assembly_cmps.empty? && new_hash_content['components'].nil?
        new_hash_content.merge!('nodes' => assembly_nodes) if !assembly_nodes.empty? && new_hash_content['nodes'].nil?
        new_hash_content.merge!('attributes' => assembly_attrs) if !assembly_attrs.empty? && new_hash_content['attributes'].nil?

        { 'assembly' => new_hash_content }
      end

      private

      def parse_attributes(assembly_hash_attrs, existing_attrs)
        new_attrs = {}
        existing_attrs.each do |attr_name|
          if attribute = assembly_hash_attrs.delete(attr_name)
            new_attrs.merge!(attr_name => attribute)
          end
        end

        new_attrs.merge(assembly_hash_attrs)
      end

      def parse_components(assembly_hash_cmps, existing_cmps)
        new_cmps = []

        existing_cmps.each do |cmp|
          cmp_name = cmp.is_a?(String) ? cmp : cmp.keys.first

          if cmp_match = assembly_hash_cmps.find{ |ah_cmp| ah_cmp.eql?(cmp_name) || (ah_cmp.is_a?(Hash) && ah_cmp[cmp_name]) }
            assembly_cmp = assembly_hash_cmps.delete(cmp_match)
            parsed_assembly_cmp = assembly_cmp.is_a?(String) ? assembly_cmp : parse_single_component_content(cmp_name, assembly_cmp, cmp)
            new_cmps << parsed_assembly_cmp
          end
        end

        new_cmps.concat(assembly_hash_cmps)
      end

      def parse_nodes(assembly_hash_nodes, existing_nodes)
        new_nodes = {}

        existing_nodes.each do |node_name, node_content|
          if node = assembly_hash_nodes.delete(node_name)
            node[:components] = parse_components(node[:components], node_content['components'])
            new_nodes.merge!(node_name => node)
          end
        end

        new_nodes.merge(assembly_hash_nodes)
      end

      def parse_single_component_content(cmp_name, assembly_cmp, cmp)
        existing_cmp_content = cmp[cmp_name]
        cmp_content = assembly_cmp[cmp_name]
        return unless existing_cmp_content

        assembly_cmp_links = cmp_content[:component_links]
        new_cmp_links = {}
        if existing_cmp_links = assembly_cmp_links && existing_cmp_content['component_links']
          existing_cmp_links.each do |k, v|
            new_cmp_links.merge!(k => assembly_cmp_links.delete(k))
          end
        end

        new_cmp_links.merge!(assembly_cmp_links) if assembly_cmp_links
        cmp_content[:component_links] = new_cmp_links unless new_cmp_links.empty?
        assembly_cmp
      end

      def parse_comments_and_empty_lines(new_hash_content)
        nodes_comments = get_nodes_comments()
        add_nodes_comments(new_hash_content, nodes_comments)
      end

      def add_nodes_comments(new_hash_content, nodes_comments)
        nodes_hash = new_hash_content['nodes']
        cmps_hash  = new_hash_content['components']
        nodes_comments.each do |comment|
          if node_name = comment[:node_name] && comment[:node_name].gsub(/:$/, '')
            subhash   = nodes_hash.to_a
            insert_at = subhash.index(subhash.assoc(node_name))
            nodes_hash = Hash[subhash.insert(insert_at, [comment[:comment_content], ''])]
          elsif assembly_cmp_name = comment[:assembly_component] && comment[:assembly_component].gsub(/:$/, '')
            subhash   = cmps_hash.to_a
            insert_at = subhash.index(subhash.assoc(assembly_cmp_name))
            cmps_hash = Hash[subhash.insert(insert_at, [comment[:comment_content], ''])]
          end
        end

        new_hash_content['nodes'] = nodes_hash
        new_hash_content['components'] = cmps_hash

        new_hash_content
      end

      def get_nodes_comments()
        last = nil
        comments = []
        assembly_components = nil
        assembly_nodes = nil
        node_name = nil
        node_indent = nil
        assembly_component_name = nil
        assembly_components_indent = nil
        next_is_node = nil

        assembly_nodes_array = []

        @raw_content.each_line do |line|
          name = line.strip()

          if name.eql?('nodes:')
            assembly_nodes = true
            assembly_components = nil
            assembly_component_name = nil
            assembly_components_indent = nil
          end

          if name.eql?('components:')
            if node_indent && (line[/\A */].size <= node_indent)
              if is_comment?(last)
                comments.last.delete(:node_name)
                comments.last[:assembly_component] = name
                assembly_component_name = name
              end
              assembly_components = true
            end
          end

          is_equal_node_indent = node_indent && line[/\A */].size == node_indent
          if last.eql?('nodes:') || next_is_node || is_equal_node_indent
            if is_comment?(name)
              next_is_node = true
            else
              node_name = name
              node_indent = line[/\A */].size
              next_is_node = nil
            end
          end

          if last.eql?('components:') && assembly_components
            assembly_nodes = nil
            assembly_component_name = name
            assembly_components_indent = line[/\A */].size
          end


          if is_comment?(name)
            if last && is_comment?(last)
              last_content = comments.last[:comment_content]
              comments.last[:comment_content] = last_content + line
            else
              comments << { :comment_name => name, :comment_content => line }
            end
          else
            if last && is_comment?(last)
              comments.last[:above] = name
              if assembly_component_name
                comments.last[:assembly_component] = name
              elsif node_name
                comments.last[:node_name] = node_name
              end
            end
          end

          last = name
        end

        comments
      end

      def is_comment?(line)
        line.start_with?('#')
      end
    end
  end
end; end; end