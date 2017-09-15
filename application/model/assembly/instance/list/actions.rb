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
      require_relative('actions/info')
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
          # Calling assembly_instance.get_task_templates the second time after
          # Task::Template.get_serialized_content will have different result 
          Task::Template.get_serialized_content(assembly_instance, nil)
          service_actions = assembly_instance.get_task_templates(set_display_names: true)
        end
        
        service_actions.each do |service_action|
          ret << { display_name: service_action[:display_name], action_type: "service" }
        end
      end

      def add_component_create_actions!(ret)
        action_info_array = []
        assembly_instance.get_augmented_components.each do |component|
          node            = component[:node]
          component_type  = component[:component_type].gsub('__', '::')
          component_title = ((match = component[:display_name].match(/.*\[(.*)\]/)) && match[1])

          action_info = Info.new(component_type, component_title, Info::CREATE_METHOD, node: node)
          if node.is_node_group?
            action_info_array += expand_node_group_members(node, action_info)
          else
            action_info_array << action_info
          end
        end

        ret.concat(Info.display_form(action_info_array))
      end

      def add_component_actions_with_methods!(ret)
        action_info_array = []
        Task::Template::Action::AdHoc.list(assembly_instance, :component_instance, {return_nodes: true}).each do |component_action|
          method_name = component_action[:method_name]
          next if method_name == Info::CREATE_METHOD

          node            = component_action[:node]
          component_type  = component_action[:component_type]
          component_title = ((match = component_action[:display_name].match(/.*\[(.*)\]/)) && match[1])

          action_info = Info.new(component_type, component_title, method_name, node: node)
          if node.is_node_group?
            action_info_array += expand_node_group_members(node, action_info)
          else
            action_info_array << action_info
          end
        end
        
        ret.concat(Info.display_form(action_info_array))
      end

      # if there is node group in service instance, expand node group memebers and display them in list-actions
      def expand_node_group_members(node, action_info)
        action_info_array = []

        # add node group name to list action
        action_info_array << action_info
        
        component_type  = action_info.component_type
        component_title = action_info.component_title 
        method_name     = action_info.method_name

        members = node.get_node_group_members.sort_by{ |m| m[:index].to_i }

        if members.size <=  Info::MAX_NODE_GROUP_MEMBERS_TO_DISPLAY
          members.each { |ng_member| action_info_array << Info.new(component_type, component_title, method_name, node: ng_member) }
        else
          node_group_range = [members.first[:index], members.last[:index]]
          action_info_array << Info.new(component_type, component_title, method_name, node_name: node.display_name, node_group_range: node_group_range)
        end

        action_info_array
      end

    end
  end
end

