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
        require_relative('component_link/diff')

        def initialize(component_link, base_assembly_instance)
          super()
          @component_link         = component_link
          @base_assembly_instance = base_assembly_instance
        end
        private :initialize

        def self.generate_content_input?(component_links, base_assembly_instance)
          content_input_links = component_links.inject(ContentInputHash.new) do |h, cmp_link|
            content_input_link = new(cmp_link, base_assembly_instance).generate_content_input?
            content_input_link ? h.merge!(component_link_name(cmp_link) => content_input_link) : h
          end

          content_input_links.empty? ? nil : sort(content_input_links)
        end
        
        def generate_content_input?
          set_id_handle(component_link)
          dependent_component = component_link[:output_component]
          set(:Value, dependent_component.display_name_print_form)
          unless base_assembly_instance.id == dependent_component.get_field?(:assembly_id)
            set(:ExternalServiceName, service_name(dependent_component))
          end 
          self
        end

        def skip_for_generation?
          super or matches_tag_type?(:desired__derived__propagated) or matches_tag_type?(:actual)
        end

        ### For diffs
        def diff?(attribute_parse, qualified_key, opts = {})
          unless skip_for_generation?
            cur_val = val(:Value)
            new_val = attribute_parse.respond_to?(:val) ? attribute_parse.val(:Value) : attribute_parse
            create_diff?(cur_val, new_val, qualified_key)
          end
        end

        def self.diff_set(cmp_links_gen, cmp_links_parse, qualified_key, opts = {})
          diff_set_from_hashes(cmp_links_gen, cmp_links_parse, qualified_key, opts)
        end

        private

        attr_reader :component_link, :base_assembly_instance

        def self.sort(content_input_links)
          content_input_links.keys.sort.inject(ContentInputHash.new) do |h, key|
            h.merge(key => content_input_links[key])
          end
        end

        def component_link_name
          component_link.display_name
        end

        def self.component_link_name(cmp_link)
          cmp_link.display_name
        end

        def service_name(component)
          Model.object_from_id(component.model_handle, component.get_field?(:assembly_id)).display_name
        end

      end
    end
  end
end; end

