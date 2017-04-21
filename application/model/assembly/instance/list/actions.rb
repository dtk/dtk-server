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
module DTK
  module Assembly::Instance::List
    class Actions
      module Mixin
        def list_actions(type = nil)
          Actions.new(self).list(type)
        end
      end

      def initialize(assembly_instance)
        @assembly_instance = assembly_instance
      end

      def list(type = nil)
        ret = []
        add_service_level_actions!(ret) if type.nil? || type.eql?('service')
        if type.nil? || type.eql?('component')
          add_component_create_actions!(ret) 
          add_component_actions_with_methods!(ret)
        end
        ret
      end

      private

      attr_reader :assembly_instance

      def add_service_level_actions!(ret)
        service_actions = assembly_instance.get_task_templates(set_display_names: true)
        create_action = service_actions.find{ |action| action[:display_name].eql?('create')}
        if service_actions.empty? || create_action.nil?
          # this will generate simple create action for service instance
          Task::Template.get_serialized_content(assembly_instance, nil)
          service_actions = get_task_templates(set_display_names: true)
        end
        
        service_actions.each do |service_action|
          ret << { display_name: service_action[:display_name], action_type: "service" }
        end
      end

      ActionInfo = Struct.new(:node, :component_type, :component_title, :method_name)
      CREATE_METHOD = 'create'

      def add_component_create_actions!(ret)
        action_info_array = []
        assembly_instance.get_augmented_components.each do |component|
          node            = component[:node]
          component_type  = component[:component_type].gsub('__', '::')
          component_title = ((match = component[:display_name].match(/.*\[(.*)\]/)) && match[1])

          action_info = ActionInfo.new(node, component_type, component_title, CREATE_METHOD)
          if node.is_node_group?
            action_info_array += expand_node_group_members(node, action_info)
          else
            action_info_array << action_info
          end
        end

        ret.concat(summarize(action_info_array))
      end

      def add_component_actions_with_methods!(ret)
        action_info_array = []
        Task::Template::Action::AdHoc.list(assembly_instance, :component_instance, {return_nodes: true}).each do |component_action|
          method_name = component_action[:method_name]
          next if method_name == CREATE_METHOD

          node            = component_action[:node]
          component_type  = component_action[:component_type]
          component_title = ((match = component_action[:display_name].match(/.*\[(.*)\]/)) && match[1])

          
          action_info = ActionInfo.new(node, component_type, component_title, method_name)
          if node.is_node_group?
            action_info_array += node_group_member_actions
          else
            action_info_array << action_info
          end
        end
        
        ret.concat(summarize(action_info_array))
      end

      # if there is node group in service instance, expand node group memebers and display them in list-actions
      def expand_node_group_members(node, action_info)
        info = action_info # alias
        action_info_array = []

        # add node group name to list action
        action_info_array << info

        members = node.get_node_group_members
        members.sort_by! { |m| m[:index].to_i }

        if members.size <= 2
          members.each { |member| action_info_array << ActionInfo.new(member, info.component_type, info.component_title, info.method_name) }
        else
          first_index = members.first[:index]
          last_index = members.last[:index]
          raise "Need to treat"
#          action_info_array << { node: "#{node[:display_name]}:[#{first_index}-#{last_index}]", component_ref: component_ref, component_title: component_title }
        end

        action_info_array
      end

      def summarize(action_info_array)
        ret = []
        index_iterate(action_info_array) do |node_name, component_type, method_name, action_info_array|
          info_element = 
            if action_info_array.size == 1
              action_info_array.first
            else
              # everything wil be same in action_info_array elements except for title
              sample_info = action_info_array.first
              ActionInfo.new(sample_info.node, component_type, title_summary(action_info_array), method_name) 
            end
          ret << summarize_element(info_element)
        end
        ret
      end

      TITLE_SUMMARY = 'NAME'
      COUNT_TO_USE_TITLE_SUMMARY = 4
      TITLE_DELIM = ','
      def title_summary(action_info_array)
        if action_info_array.size > COUNT_TO_USE_TITLE_SUMMARY
          TITLE_SUMMARY
        else
          action_info_array.map(&:component_title).join(TITLE_DELIM) 
        end
      end
      
      def index_iterate(action_info_array, &block)
        index_action_info(action_info_array).each_pair do |node_name, ndx_by_component_type|
          ndx_by_component_type.each_pair do |component_type, ndx_by_method_name|
            ndx_by_method_name.each_pair do |method_name, action_info_array|
              block.call(node_name, component_type, method_name, action_info_array)
            end
          end
        end
      end

      # indexed by [node_name][component_type][method_name]
      def index_action_info(action_info_array)
        ret = {}
        action_info_array.each do |action_info|
          node_name      = node_name(action_info.node)
          component_type = action_info.component_type
          method_name    = action_info.method_name || CREATE_METHOD
          (((ret[node_name] ||= {})[component_type] ||= {})[method_name] ||= []) << action_info
        end
        ret
      end
      
      def summarize_element(action_info)
        info             = action_info # alias
        node             = info.node
        method_name      = info.method_name
        is_create_method = (method_name.nil? or method_name == CREATE_METHOD)
        
        display_name = ''
        display_name << "#{node_name(node)}/" unless node.is_assembly_wide_node?
        display_name << info.component_type
        display_name << "[#{info.component_title}]" if info.component_title
        display_name << ".#{method_name}" unless is_create_method
        
        action_type = (is_create_method ? 'component_create' : 'component_action')
        { display_name: display_name, action_type: action_type }
      end

      def node_name(node)
        node.node_component_ref
      end
      
    end
  end
end

