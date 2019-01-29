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
module DTK; class Task; class Template; class Stage
  class InterNode
    class MultiNode < self
      def initialize(serialized_multinode_action)
        # require 'byebug'
        # require 'byebug/core'
        # Byebug.wait_connection = true
        # Byebug.start_server('localhost', 5555)
        # debugger
        super(serialized_multinode_action[:name], serialized_multinode_action[:breakpoint], serialized_multinode_action[:retry], serialized_multinode_action[:attempts])
        @ordered_components, @components_or_actions_key = components_or_actions(serialized_multinode_action)
        @node_object_id = serialized_multinode_action[:node_object_id] || nil 
        @node_object_name = serialized_multinode_action[:node_object_name] || nil
        @breakpoint = serialized_multinode_action[:breakpoint]
        @retry = serialized_multinode_action[:retry]
        @attempts = serialized_multinode_action[:attempts]
        unless @ordered_components 
          fail ParsingError::MissingComponentOrActionKey.new(serialized_multinode_action, stage: serialized_multinode_action[:name]) 
        end
      end

      def has_breakpoint?
        @breakpoint
      end

      def serialization_form(opts = {})
        if opts[:form] == :explicit_instances
          super
        else
          serialized_form_with_name().merge(@components_or_actions_key => @ordered_components)
        end
      end

      # opts can have keys:
      #  :just_parse (Boolean)
      def self.parse_and_reify(multi_node_type, serialized_multinode_action, action_list, opts = {})
        klass(multi_node_type).new(serialized_multinode_action).parse_and_reify!(action_list, opts)
      end

      private

      # returns [ordered_components, components_or_actions_key] if match; otherwise returns nil
      def components_or_actions(serialized_el)
        if key_val = Constant.matching_key_and_value?(serialized_el, :ComponentsOrActions)
          ordered_components = key_val.values.first
          components_or_actions_key = key_val.keys.first
          ordered_components = ordered_components.kind_of?(Array) ? ordered_components : [ordered_components]
          [ordered_components, components_or_actions_key]
        end
      end

      def self.klass(multi_node_type)
        if Constant.matches?(multi_node_type, :AllApplicable)
          Applicable
        else
          fail ParsingError.new("Illegal multi node type (#{multi_node_type}); #{Constant.its_legal_values(:AllApplicable)}")
        end
      end

      # This is used to include all applicable classes
      class Applicable < self
        # opts can have keys:
        #  :just_parse (Boolean)
        def parse_and_reify!(action_list, opts ={})
          ret = self
       
          if action_list.nil?
            if opts[:just_parse]
              # This wil raise error if a parsing error
              @ordered_components.each { |serialized_action| Action::WithMethod.parse(serialized_action) }
            else
              Log.error("Unexpected that action_list.nil? while opts[:just_parse] is not true")
            end
            return ret
          end 
            
          info_per_node = {} #indexed by node_id
          @ordered_components.each do |serialized_action|
            cmp_ref = Action::WithMethod.parse_component_name_ref(serialized_action)
            cmp_type = cmp_ref
            cmp_title = nil
            if cmp_ref =~ CmpRefWithTitleRegexp
              cmp_type = Regexp.last_match(1)
              cmp_title = Regexp.last_match(2)
            end

            matching_actions = action_list.select { |a| a.match_component_ref?(cmp_type, cmp_title) }
            # require 'byebug'
            # require 'byebug/core'
            # Byebug.wait_connection = true
            # Byebug.start_server('localhost', 5555)
            # debugger
            matching_actions.each do |a|
              node_id = @node_object_id ? @node_object_id : a.node_id
              node_name = @node_object_name ? @node_object_name : a.node_name
              pntr = info_per_node[node_id] ||= { actions: [], name: node_name, id: node_id, retry: @retry || opts[:retry], attempts: opts[:attempts] }
              pntr[:actions] << serialized_action
            end
          end
          info_per_node.each_value do |n|
            opts.merge!(:retry_node => n[:retry])
            if node_actions = InterNode.parse_and_reify_node_actions?({ Constant::OrderedComponents => n[:actions] }, n[:name], n[:id], action_list, opts)
              merge!(node_actions)
            end
          end
          # require 'byebug'
          # require 'byebug/core'
          # Byebug.wait_connection = true
          # Byebug.start_server('localhost', 5555)
          # debugger
          ret
        end
        CmpRefWithTitleRegexp = /(^[^\[]+)\[([^\]]+)\]$/

        #temporary method for easier context for questions
        def replace_workflow_info(workflow_action_def, nodes)

          self.each do |app|
            # require 'byebug'
            # require 'byebug/core'
            # Byebug.wait_connection = true
            # Byebug.start_server('localhost', 5555)
            # debugger
            app[1].reduce.reduce.action.action_defs.first[:content][:workflow][:subtasks] = workflow_action_def
            #hardcoded mongo:1
            node = nodes.find { |node| node[:display_name].eql? 'mongo:1' }
            app[1].reduce.reduce.component[:node] = node
           # app[1].node = node

          end
        end
      end
    end
  end
end; end; end; end
