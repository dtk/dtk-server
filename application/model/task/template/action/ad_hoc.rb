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
module DTK; class Task; class Template
  class Action
    class AdHoc
      # opts can have
      #  :method_name
      def initialize(assembly, component, opts = {})
        @assembly              = assembly
        @component             = component
        @method_name           = opts[:method_name]
        @task_template_content = ret_task_template_content
      end

      attr_reader :task_template_content

      def task_action_name
        ret = component_name
        if @method_name
          ret << ".#{@method_name}"
        end
        ret
      end

      def self.list(assembly, type, opts = {})
        List.list(get_action_list(assembly), type, opts)
      end

      private

      def get_action_list
        self.class.get_action_list(@assembly)
      end
      def self.get_action_list(assembly)
        ActionList::ConfigComponents.get(assembly)
      end

      def ret_task_template_content
        action_list = get_action_list
        Content.parse_and_reify(serialized_content, action_list)
      end

      def serialized_content
        ret = { node: @component.get_node.get_field?(:display_name) }
        ret.merge(@method_name ? with_method_name : without_method_name)
      end

      # TODO: encapsulate the delimeters with parsing routines
      def without_method_name
        { components: [component_name] }
      end

      def with_method_name
        { actions: ["#{component_name}.#{@method_name}"] }
      end

      def component_name
        @component.display_name_print_form
      end

      module List
        def self.list(action_list, type, opts = {})
          action_list_display_form = action_list_display_form(action_list, type, opts)

          case type
            when :component_instance
              action_list_display_form.sort { |a, b| a[type] <=> b[type] }
            when :component_type
              just_component_types(action_list_display_form).sort { |a, b| a[type] <=> b[type] }
            else fail ErrorUsage.new("Illegal type (#{type})")
          end
        end

        private

        def self.action_list_display_form(action_list, type, opts = {})
          action_list.inject([]) do |array, component_action|
            array + action_display_form(component_action, type, opts)
          end
        end

        def self.action_display_form(component_action, type, opts = {})
          ret = []
          action_defs = component_action.action_defs
          unless action_defs.empty?
            action_defs.each do |action_def|
              ac_def = {
                component_instance: type == :component_instance && component_action.display_name_print_form(node_prefix: true),
                component_type: component_action.component_type_print_form,
                method_name: action_def.get_field?(:method_name),
                display_name: component_action.display_name_print_form
              }
              if node = opts[:return_nodes] && component_action.configured_node
                ac_def.merge!(node: component_action.configured_node)
              end
              ret << ac_def
            end
          end
          ret
        end

        def self.just_component_types(action_list_display_form)
          ret = []
          action_list_display_form.each do |new_el|
            unless ret.find { |r| r[:component_type] == new_el[:component_type] && r[:method_name] == new_el[:method_name] }
              ret << Aux.hash_subset(new_el, [:component_type, :method_name])
            end
          end
          ret
        end
      end
    end
  end
end; end; end
