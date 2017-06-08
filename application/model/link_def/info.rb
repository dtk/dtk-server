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
    # Each element has form
    #   <Assemby::Template>
    #   id: ID
    #   node: NODE
    #   component_ref: ComponentRef
    #   nested_component: ComponentTemplate
    #   link_def:
    #     <LinkDef>
    #     link_def_links:
    #     - LinkDef::Link
    class Info < Array
      def self.component_ref_cols
        ComponentRef.common_cols
      end
      def self.nested_component_cols
        [:id, :display_name, :component_type, :extended_base, :implementation_id, :node_node_id, :only_one_per_node]
      end

      def self.get_link_def_info(assembly_template)
        link_defs_info = new(assembly_template.get_objs(cols: [:template_link_defs_info]))
        link_defs_info.add_link_def_links!
      end

      def add_link_def_links!
        ndx_link_defs = link_defs.inject({}) { |h, link_def| h.merge(link_def.id => link_def) }
        return self if ndx_link_defs.empty?
        sp_hash = {
          cols: [:id, :group_id, :link_def_id, :remote_component_type],
          filter: [:oneof, :link_def_id, link_defs.map(&:id)]
        }
        link_def_link_mh = link_defs.first.model_handle(:link_def_link)
        Model.get_objs(link_def_link_mh, sp_hash).each do |link_def_link|
          link_def = ndx_link_defs[link_def_link[:link_def_id]]
          (link_def[:link_def_links] ||= []) << link_def_link
        end
        self
      end

      # signature generate_link_def_link_pairs do |link_def, link|
      def generate_link_def_link_pairs(&body)
        link_defs.each do |link_def|
          (link_def[:link_def_links] || {}).each { |link| body.call(link_def, link) }
        end
      end

      def link_defs
        ret = []
        each do |ld_info|
          if link_def = ld_info[:link_def]
            ret << link_def
          end
        end
        ret
      end
    end
  end
end
