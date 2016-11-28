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
      class ComponentLink < ContentInputHash
        def initialize(component_link)
          super()
          @component_link = component_link
        end
        private :initialize

        def self.generate_content_input?(component_links, opts = {})
          content_input_attributes = component_links.inject(ContentInputHash.new) do |h, cmp_link|
            content_input_attr = new(cmp_link).generate_content_input?
            content_input_attr ? h.merge!(component_link_name(cmp_link) => content_input_attr) : h
          end

          content_input_attributes.empty? ? nil : sort(content_input_attributes)
        end
        
        def generate_content_input?
          cmp_link = DTK::Assembly::Instance::ServiceLink.print_form_hash(@component_link, hide_assembly_wide_node: true)
          set(:Value, cmp_link[:dependent_component])
          self
        end

        def skip_for_generation?
          super or matches_tag_type?(:desired__derived__propagated) or matches_tag_type?(:actual)
        end

        ### For diffs
        def diff?(attribute_parse, qualified_key)
          unless skip_for_generation?
            cur_val = val(:Value)
            new_val = attribute_parse.val(:Value)
            create_diff?(cur_val, new_val, qualified_key)
          end
        end

        def self.diff_set(attributes_gen, attributes_parse, qualified_key, _opts = {})
          # The method array_of_diffs_on_matching_keys; so assuming that user is not adding attributes
          # and by design not erroneously catching hidden attributes, which will show up in self (attribute_gen),
          # but not attributes_parse
          array_of_diffs_on_matching_keys(attributes_gen, attributes_parse, qualified_key)
        end

        private

        def self.sort(content_input_attributes)
          content_input_attributes.keys.sort.inject(ContentInputHash.new) do |h, key|
            h.merge(key => content_input_attributes[key])
          end
        end

        def component_link_name
          @component_link[:display_name]
        end

        def self.component_link_name(cmp_link)
          cmp_link.display_name
        end

      end
    end
  end
end; end

