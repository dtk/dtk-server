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
  class LinkDef::AutoComplete
    class DependencyCandidates
      require_relative('dependency_candidates/constraints')

      Element = Struct.new(:depth, :aug_component)

      def initialize(assembly_instance)
        # array of Elements
        @array = dependency_candidates_array(assembly_instance, 1)
      end

      # opts can have keys:
      #   :components - base components explicitly given
      def base_aug_components(opts = {})
        ret = self.array.select { |element| element.depth == 1 }.map { |element| element.aug_component }
        if components = opts[:components]
          matching_component_ids = components.map(&:id)
          ret.reject!{ |aug_component| ! matching_component_ids.include?(aug_component.id) }
        end
        ret
      end

      def matching_components(link_def, base_component)
        link_def_links = link_def.get_link_def_links(cols: [:id, :display_name, :content, :link_def_id, :remote_component_type])
        
        # get constraints from link_def dsl content and use them later to match link_defs on auto-complete
        constraints = nil
        preferences = nil
        if link_def_content = !link_def_links.empty? && link_def_links.first[:content]
          unless link_def_content.empty?
            constraints = link_def_content[:constraints]
            preferences = link_def_content[:preferences]
          end
        end

        dependent_component_types = link_def_links.map { |link| link[:remote_component_type] }.uniq

        matching_elements = []
        self.array.each do |element|
          dep_component = element.aug_component
          next unless dependent_component_types.include?(dep_component[:component_type])
          if constraints
            matching_elements << element if Constraints.match?(constraints, dep_component, base_component)
          else
            matching_elements << element
          end
        end

        case matching_elements.size
        when 0
          []
        when 1
          [matching_elements.first.aug_component]
        else
          prune_using_preferences(matching_elements, explicit_preferences: preferences)
        end
      end

      protected 

      attr_reader :array

      private

      def dependency_candidates_array(assembly_instance, depth)
        ret = get_augmented_components(assembly_instance).map do |aug_component| 
          Element.new(depth, aug_component) 
        end
        ServiceAssociations.get_parents(assembly_instance).each do |parent_assembly_instance|
          ret += dependency_candidates_array(parent_assembly_instance, depth + 1)
        end
        ret
      end

      def get_augmented_components(assembly_instance)
        assembly_instance.get_augmented_components(Opts.new.merge(detail_to_include: [:component_dependencies]))
      end

      # opts can have keys
      #   :explicit_preferences
      def prune_using_preferences(matching_elements, opts = {})
        fail Error, "Not suppurting explicit_preferences" if opts[:explicit_preferences]
        # prefer element with lower number; 1 - means assembly instance, 2 means its parent, ...
        closest_depth = matching_elements.map(&:depth).min
        matching_elements.select { |element| element.depth == closest_depth }.map(&:aug_component)
      end

    end
  end
end
