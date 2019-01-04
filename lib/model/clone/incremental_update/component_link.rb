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
module DTK; class Clone
  class IncrementalUpdate
    class ComponentLink < self
      def update?
        links = get_instances_templates_links()
        linkdefs = update_model?(links) || []
        linkdefs.each do |linkdef|
          new_links = ::DTK::Clone::InstanceTemplate::Links.new()
          linkdef_instances = linkdef.instances 
            linkdef.templates.each do |template|   
              instance = linkdef_instances.find{|ld| ld[:ancestor_id].eql?(template[:id])}
              unless instance
                sp_hash = {
                  cols: [:id, :group_id, :display_name, :description, :ancestor_id, :local_or_remote, :link_type, :component_component_id, :ref],
                  filter: [:eq, :ancestor_id, template[:id]]
                }
                instance = Model.get_objs(template.model_handle, sp_hash).first
              end
              new_links.add(instance, template)
            end
          ComponentLinks.new(new_links).update?()
        end
      end

      private

      # TODO: put in equality test so that does not need to do the modify equal objects
      def equal_so_dont_modify?(_instance, _template)
        false
      end

      def get_ndx_objects(component_idhs)
        ret = {}
        ::DTK::Component.get_component_links(component_idhs, cols_plus: [:component_id, :ref, :ancestor_id]).each do |r|
          (ret[r[:component_component_id]] ||= []) << r
        end
        ret
      end
    end
  end
end; end
