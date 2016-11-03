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
    # This module is responsible for incremental clone (incremental update) when component module
    # in a service instance are updated the compoennt instance needs to be updated
    class Component < self
      def initialize(project_idh, module_branch)
        @project_idh = project_idh
        @module_branch = module_branch
        @module_branch_id = @module_branch[:id]
      end

      def update?(components, opts = {})
        cmps_needing_update = components.select { |cmp| component_needs_update?(cmp, opts) }
        return if cmps_needing_update.empty?
        # putting this here but not in other update functions in IncrementalUpdate because this is top level entry point
        Model.Transaction do
          update(cmps_needing_update, opts)
        end
      end

      private

      # opts can have keys
      #   
      def update(components, opts = {})
        # get mapping between component instances and their templates
        # component templates indexed by component type
        links = get_instance_template_links(components, opts)
        rows_to_update = components.map do |cmp|
          cmp_template = links.template(cmp)
          {
            id: cmp[:id],
            module_branch_id: @module_branch_id,
            version: cmp_template[:version],
            locked_sha: nil, #this serves to let component instance get updated as this branch is updated
            implementation_id: cmp_template[:implementation_id],
            ancestor_id: cmp_template[:id],
            external_ref: cmp_template[:external_ref]
          }
        end
        Model.update_from_rows(@project_idh.createMH(:component), rows_to_update)
        update_children(links)
      end

      def update_children(links)
        Dependency.new(links).update?()
        # TODO: DTK-2068; put in logic to update component instances that are associated with componenttemplate with updated link defs 
        IncludeModule.new(links).update?()
        Attribute.new(links).update?()
      end

      def component_needs_update?(cmp, opts = {})
        opts[:meta_file_changed] ||
        needs_to_be_moved_to_assembly_branch?(cmp) ||
        has_locked_sha?(cmp)
      end

      def needs_to_be_moved_to_assembly_branch?(cmp)
        (cmp.get_field?(:module_branch_id) != @module_branch_id)
      end

      def has_locked_sha?(cmp)
        (cmp.key?(:locked_sha) && !cmp[:locked_sha].nil?) ||
         # added protection in case :locked_sha not in ruby object
         !cmp.get_field?(:locked_sha).nil?
      end

      # opts can have keys:
      #   
      def get_instance_template_links(cmps, opts = {})
        ret = InstanceTemplate::Links.new()
        component_types = cmps.map { |cmp| cmp.get_field?(:component_type) }.uniq
        version_field = @module_branch.get_field?(:version)
        match_el_array = component_types.map do |ct|
          DTK::Component::Template::MatchElement.new(
           component_type: ct,
           version_field: version_field
          )
        end
        ndx_cmp_type_template = DTK::Component::Template.get_matching_elements(@project_idh, match_el_array, opts).inject({}) do |h, r|
          h.merge(r[:component_type] => r)
        end
        cmps.each do |cmp|
          if template = ndx_cmp_type_template[cmp[:component_type]] # this should be non null; "if" just for protection
            ret.add(cmp, template)
          end
        end
        ret
      end
    end
  end
end; end
