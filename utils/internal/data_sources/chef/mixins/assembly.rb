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
module XYZ
  module DSConnector
    module ChefMixinAssembly # TODO: unify with code in R8Cookbook
      def normalize_attribute_values(target, attr_val_hash, node, metadata = nil)
        attr_val_hash.each do |key, value|
          if value.is_a?(Hash)
            if value.key?('external_ref')
              target[key] = process_external_ref(value['external_ref'], node, metadata)
            else
              # TODO: this can be a Mash; should probably convert before hand to avoid patch below
              target[key] ||= HashObject::AutoViv.create()
              normalize_attribute_values(target[key], value, node, metadata)
            end
          elsif value.is_a?(Array)
            target[key] = value.map do |child|
              if child.is_a?(Hash)
                child_target = HashObject::AutoViv.create()
                normalize_attribute_values(child_target, child, node, metadata)
              else
                child
              end
            end
          else
            target[key] = value
          end
        end
        target
      end

      def process_external_ref(external_ref, node = nil, metadata = nil)
        return nil unless external_ref
        case external_ref['type'].to_sym
        when :chef_search
          process_external_ref__chef_search(external_ref)
        when :chef_search_singleton
          (process_external_ref__chef_search(external_ref) || []).first
        when :chef_node
          process_external_ref__chef_node(external_ref)
        when :chef_attribute
          process_external_ref__chef_attribute(external_ref, node, metadata)
        else
          fail Error.new('not implemented yet')
        end
      end

      private

      def process_external_ref__chef_search(external_ref)
        if external_ref['ref'] =~ %r{^search\[(.+)\]\[(.+)\]$}
          object_type = Regexp.last_match(1).to_sym
          search_pattern = Regexp.last_match(2)
          return Search.get_list(object_type, search_pattern).map(&:name)
        end
        fail Error.new("search_pattern (#{external_ref['ref']}) has incorrect syntax")
      end

      def process_external_ref__chef_node(external_ref)
        return Regexp.last_match(1) if external_ref['ref'] =~ %r{^node_name\[(.+)\]$}
        fail Error.new("external reference (#{external_ref['ref']}) has incorrect syntax")
      end

      def process_external_ref__chef_attribute(external_ref, node, metadata)
        if external_ref['ref'] =~ %r{^node\[(.+)\]$}
          path = Regexp.last_match(1).split('][')
          if node
            return NodeState.nested_value(node[path[0]], path[1..path.size - 1])
          else
            return nil unless metadata && metadata['attributes']
            attr_info = metadata['attributes'][path.join('/')]
            return attr_info ? attr_info['default'] : nil
          end
        end
        fail Error.new("external reference (#{external_ref['ref']}) has incorrect syntax")
      end

      module NodeState
        # used so dont get error when make call like node[x][y] and node[x] does not exist
        def self.nested_value(node_attribute, path)
          nested_value_private(node_attribute, path.dup)
        end

        private

        def self.nested_value_private(node_attribute, path)
          return nil unless node_attribute.is_a?(::Chef::Node::Attribute)
          return node_attribute if path.size == 0
          return nil unless node_attribute.key?(f = path.shift)
          return node_attribute[f] if path.size == 0
          nested_value_private(node_attribute[f], path)
        end
      end
    end
  end
end