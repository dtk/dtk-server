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
module DTK; class ModuleDSL; class V3
  class IncrementalGenerator; class LinkDef
    class LinkDefsSection < self
      def generate
        link_def_links = @aug_link_def.required(:link_def_links)
        if link_def_links.empty?
          fail Error.new('Unexpected that link_def_links is empty')
        end
        @aug_link_def[:link_def_links].inject(PossibleLinks.new) do |pl, link_def_link|
          cmp, link = choice_info(ObjectWrapper.new(link_def_link))
          pl.deep_merge(cmp, link)
        end
      end

      def merge_fragment!(full_hash, fragment, context = {})
        ret = full_hash
        return ret unless fragment
        component_fragment = component_fragment(full_hash, context[:component_template])
        if link_defs_fragment = component_fragment['link_defs']
          component_fragment['link_defs'] = PossibleLinks.reify(link_defs_fragment)
          fragment.each do |cmp, link|
            component_fragment['link_defs'] = component_fragment['link_defs'].deep_merge(cmp, link)
          end
        else
          component_fragment['link_defs'] = fragment
        end
        ret
      end

      private

      # returns cmp,link
      def choice_info(link_def_link)
        link = Link.new
        cmp = link_component(link_def_link)
        link['location'] = link_location(link_def_link)
        if dependency_name = @aug_link_def[:link_type]
          unless dependency_name == cmp
            link['dependency_name'] = dependency_name
          end
        end
        if link_required_is_false?(link_def_link)
          ret['required'] = false
        end
        ams = link_def_link.object.attribute_mappings()
        if ams and not ams.empty?
          remote_cmp_type = link_def_link.required(:remote_component_type)
          link['attribute_mappings'] = ams.map { |am| attribute_mapping(ObjectWrapper.new(am), remote_cmp_type) }
        end
        [cmp, link]
      end
    end
  end; end
end; end; end