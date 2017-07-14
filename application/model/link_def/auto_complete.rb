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
  class LinkDef
    class AutoComplete
      require_relative('auto_complete/dependency_candidates')
      require_relative('auto_complete/internal_links')

      # opts can have keys:
      #   :components - base components explicitly given
      def self.autocomplete_component_links(assembly_instance, opts = {})
        dependency_candidates = DependencyCandidates.new(assembly_instance)
        base_aug_components = dependency_candidates.base_aug_components(components: opts[:components])
        base_aug_components.each do |base_aug_component|
          link_matching_components(assembly_instance, base_aug_component, dependency_candidates)
        end
      end
      
      private
      
      def self.link_matching_components(assembly_instance, base_aug_component, dependency_candidates)
        if dependencies = base_aug_component[:dependencies]
          get_unlinked_link_defs(dependencies).each do |link_def|
            matching_cmps = dependency_candidates.matching_components(link_def, base_aug_component)
            case matching_cmps.size
            when 1
              begin
                assembly_instance.add_component_link(base_aug_component, matching_cmps.first)
              rescue => e
                Log.error_pp(["TODO: Trapped error after auto link; auto link should be refined to avoid this", e])
                nil
              end
            when 0
              # no matches
            else
              # more than 1 match
            end
            
          end
        end
      end
      
      def self.get_unlinked_link_defs(dependencies)
        ret_link_defs = []
        
        dependencies.each do |dep|
          if link_def = dep.respond_to?(:link_def) && dep.link_def
            ret_link_defs << link_def if dep.satisfied_by_component_ids.empty?
          end
        end
        
        ret_link_defs
      end
    end

  end
end
