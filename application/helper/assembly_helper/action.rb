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
module Ramaze::Helper
  module AssemblyHelper
    ##
    # helpers related to assembly command and control actions
    module ActionMixin
      # creates a queue object, initiates action that will push results on queue
      # if any errors, it wil just push error conditions on queue
      def initiate_action(action_queue_class, assembly, params = {}, node_pattern = {})
        InitiateAction.block(action_queue_class, params) do |action_queue|
          nodes = ret_matching_nodes(assembly, node_pattern)
          action_queue.initiate(nodes, params)
        end
      end

      def initiate_action_with_nodes(action_queue_class, nodes, params = {}, &block)
        InitiateAction.block(action_queue_class, params) do |action_queue|
          block.call if block
          action_queue.initiate(nodes, params)
        end
      end

      def initiate_execute_tests(action_queue_class, params = {})
        InitiateAction.execute_tests_block(action_queue_class, params) do |action_queue|
          action_queue.initiate
        end
      end
      module InitiateAction
        def self.block(action_queue_class, params, &block)
          opts = ::DTK::Aux.hash_subset(params, :agent_action)
          action_queue = action_queue_class.new(opts)
          begin
            block.call(action_queue)
          rescue ::DTK::ErrorUsage => e
            action_queue.push(:error, e.message)
          end

          action_queue
        end

        def self.execute_tests_block(action_queue_class, params, &block)
          action_queue = action_queue_class.new(params)
          begin
            block.call(action_queue)
          rescue ::DTK::ErrorUsage => e
            return action_queue
          end
          action_queue
        end
      end

      def ret_matching_nodes(assembly, node_pattern_x = {})
        # removing and empty or nil filters
        node_pattern = (node_pattern_x ? node_pattern_x.reject { |_k, v| v.nil? || v.empty? } : {})

        nodes = assembly.get_leaf_nodes(remove_assembly_wide_node: true)

        if node_pattern.empty?
          nodes
        else
          ret =
            if node_pattern.is_a?(Hash) && node_pattern.size == 1
              case node_pattern.keys.first
              when :node_name
                node_name = node_pattern.values.first
                MatchingNodes.filter_by_name(nodes, node_name)
              when :node_id
                node_id = node_pattern.values.first
                MatchingNodes.filter_by_id(nodes, node_id)
              when :node_identifier
                node_identifier = node_pattern.values.first
                if numeric_id?(node_identifier)
                  MatchingNodes.filter_by_id(nodes, node_identifier)
                else
                  MatchingNodes.filter_by_name(nodes, node_identifier)
                end
              end
            end
          ret || fail(::DTK::ErrorUsage.new('Unexpected form of node_pattern'))
        end
      end

      module MatchingNodes
        def self.filter_by_id(nodes, node_id)
          node_id = node_id.to_i
          # unless match = nodes.find{|n|n.id == node_id}
          unless match = nodes.select { |n| n.id.to_s.start_with?(node_id.to_s) }
            fail ::DTK::ErrorUsage.new("No node matches id (#{node_id})")
          end
          match
        end
        def self.filter_by_name(nodes, node_name)
          # unless match = nodes.find{|n|n.assembly_node_print_form() == node_name}
          unless match = nodes.select { |n| n.assembly_node_print_form().start_with?(node_name) }
            fail ::DTK::ErrorUsage.new("No node matches name (#{node_name})")
          end
          match
        end
      end
    end
  end
end