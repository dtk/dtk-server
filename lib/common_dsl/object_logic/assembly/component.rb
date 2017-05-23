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
module DTK; module CommonDSL
  module ObjectLogic
    class Assembly
      class Component < ContentInputHash
        require_relative('component/diff')
        require_relative('component/attribute')

        def initialize(aug_component, assembly_instance, assembly_component_links)
          super()
          @aug_component            = aug_component
          @assembly_instance        = assembly_instance
          @assembly_component_links = assembly_component_links
        end
        private :initialize

        def self.generate_content_input(assembly_instance)
          assembly_component_links = assembly_instance.get_augmented_port_links
          # get_augmented_nested_components returns components with nested components

          ret = ContentInputHash.new
          NodeComponent.get_augmented_nested_components(assembly_instance).each do |aug_component|
            next if aug_component[:to_be_deleted] 
            ret.merge!(component_name(aug_component) => new(aug_component, assembly_instance, assembly_component_links).generate_content_input!)
          end
          ret
        end
        
        def generate_content_input!
          set_id_handle(aug_component)

          aug_nested_components  = aug_component[:components] || []
          attributes             = aug_component[:attributes] || []
          component_links        = assembly_component_links.select { |link|  link[:input_component].id == aug_component.id }

          set?(:Attributes, Attribute.generate_content_input?(:component, attributes, component: aug_component)) unless attributes.empty?
          set?(:ComponentLinks, ComponentLink.generate_content_input?(component_links, assembly_instance)) unless component_links.empty?
          # Below adds nesetd components
          set(:Components, Component.generate_content_input__base_components(aug_nested_components, assembly_instance, assembly_component_links)) unless aug_nested_components.empty?

          if tags = tags?
            add_tags!(tags)
          end

          self
        end

        def self.generate_content_input__base_components(aug_components, assembly_instance, assembly_component_links)
          ret = ContentInputHash.new
          aug_components.each do |aug_component|
            next if  aug_component[:to_be_deleted] 
            ret.merge!(component_name(aug_component) => new(aug_component, assembly_instance, assembly_component_links).generate_content_input!)
          end
          ret
        end

        # For diffs
        # opts can have keys:
        #   :service_instance
        #   :impacted_files
        def diff?(component_parse, qualified_key, opts = {})
          aggregate_diffs?(qualified_key, opts) do |diff_set|
            diff_set.add_diff_set? Attribute, val(:Attributes), component_parse.val(:Attributes)
            diff_set.add_diff_set? ComponentLink, val(:ComponentLinks), component_parse.val(:ComponentLinks)
            diff_set.add_diff_set? Component, val(:Components), component_parse.val(:Components)
          end
        end

        # opts can have keys:
        #   :service_instance
        #   :impacted_files
        def self.diff_set(nodes_gen, nodes_parse, qualified_key, opts = {})
          diff_set_from_hashes(nodes_gen, nodes_parse, qualified_key, opts)
        end

        def self.component_delete_action_def?(component)
          ::DTK::Component::Instance.create_from_component(component).get_action_def?('delete')
        end

        private

        attr_reader :aug_component, :assembly_instance, :assembly_component_links

        def self.component_name(aug_component)
          aug_component.display_name_print_form(without_version: true)
        end
        
        def tags?
          nil
        end

      end
    end
  end
end; end
