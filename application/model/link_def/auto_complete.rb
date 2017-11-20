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

      class FatalError < ErrorUsage; end

      require_relative('auto_complete/dependency_candidates')
      require_relative('auto_complete/internal_links')
      require_relative('auto_complete/results')
      require_relative('auto_complete/result')

      def initialize(assembly_instance, opts = {})
        @assembly_instance = assembly_instance
        @components        = opts[:components]
      end
      private :initialize
      # Returns AutoComplete::Results
      # opts can have keys:
      #   :components - base components explicitly give
      def self.autocomplete_component_links(assembly_instance, opts = {})
        new(assembly_instance, opts).autocomplete_component_links
      end
      def autocomplete_component_links
        results = Results.new
        self.base_aug_components.each do |base_aug_component|
          link_matching_components!(results, base_aug_component)
        end
        results
      end

      protected
      
      attr_reader :assembly_instance

      def components?
        @components
      end
      
      def base_aug_components
        @base_aug_components ||= self.dependency_candidates.base_aug_components(components: self.components?)
      end

      def dependency_candidates
        @dependency_candidates ||= DependencyCandidates.new(self.assembly_instance)
      end

      private
      
      def link_matching_components!(results, base_aug_component)
        if dependencies = base_aug_component[:dependencies]
          get_unlinked_link_defs(dependencies).each do |link_def|
            matching_cmps = self.dependency_candidates.matching_components(link_def, base_aug_component)
            case matching_cmps.size
            when 1
              begin
                # Any method called though assembly_instance.add_component_link that wants to raise afatal error should
                # use FatalError.new(error_msg)
                # TODO: increemntally add more fatal errors as determine which shouldbe raised
                self.assembly_instance.add_component_link(base_aug_component, matching_cmps.first, raise_error: true)
              rescue FatalError => e
                fail e
              rescue => e
                Log.error_pp(["TODO: Trapped error after auto link", e])
                nil
              end
              results << Result::UniqueMatch.new(base_aug_component, link_def, matching_cmps.first)
            when 0
              results << Result::NoMatch.new(base_aug_component, link_def)
            else
              # more than 1 match
              results << Result::MultipleMatches.new(base_aug_component, link_def, matching_cmps)
            end
          end
        end
      end
      
      def get_unlinked_link_defs(dependencies)
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
