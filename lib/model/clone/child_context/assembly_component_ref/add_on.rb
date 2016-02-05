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
# for processing AssemblyComponentRefs when assembly being added is an add-on
module DTK; class Clone; class ChildContext
  class AssemblyComponentRef
    class AddOn < self
      def find_component_templates_in_assembly!
        aug_cmp_refs = get_aug_matching_component_refs()
        if aug_cmp_refs.empty?
          merge!(matches: aug_cmp_refs)
          return
        end

        ndx_template_to_instance_nodes = self[:parent_rels].inject({}) { |h, r| h.merge(r[:old_par_id] => r[:node_node_id]) }
        aug_cmp_refs.each do |cmp_ref|
          target_node_id = ndx_template_to_instance_nodes[cmp_ref.delete(:node_node_id)]
          cmp_ref.merge!(target_node_id: target_node_id)
        end
        # for each node that is not new, check if there is componenst already on target nodes that match/conflict
        matches, conflicts = Component::ResourceMatching.find_matches_and_conflicts(aug_cmp_refs)
        unless conflicts.empty?
          fail ErrorUsage.new('TODO: provide conflict message')
        end
        # remove the matches
        unless matches.empty?
          matching_ids = matches.ids()
          aug_cmp_refs.reject! { |cmp| matching_ids.include?(cmp[:id]) }
        end
        merge!(matches: aug_cmp_refs)
      end

      # MOD_RESTRUCT: this must be removed or changed to reflect more advanced relationship between component ref and template
      def matching_component_refs__virtual_col
        :component_templates
      end
    end
  end
end; end; end