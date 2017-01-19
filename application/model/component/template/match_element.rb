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
  class Component::Template
    class MatchElement < ::Hash
      def initialize(hash)
        super()
        replace(hash)
      end

      def component_type
        self[:component_type]
      end

      def version_field
        self[:version_field]
      end

      def version
        self[:version]
      end

      def namespace
        self[:namespace]
      end

      module ClassMixin
        def get_matching_elements(project_idh, match_element_array, opts = {})
          ret = []
          base_module_local_params = opts[:module_local_params]
          cmp_types = match_element_array.map(&:component_type).uniq
          versions = match_element_array.map(&:version_field)
          sp_hash = {
            cols: [:id, :group_id, :component_type, :version, :implementation_id, :external_ref],
            filter: [:and,
                     [:eq, :project_project_id, project_idh.get_id],
                     [:oneof, :version, versions],
                     [:eq, :assembly_id, nil],
                     [:eq, :node_node_id, nil],
                     [:oneof, :component_type, cmp_types]]
          }
          component_rows = get_objs(project_idh.createMH(:component), sp_hash)
          augment_with_namespace!(component_rows)
          ret = []
          unmatched = []
          match_element_array.each do |el|
            matches = component_rows.select do |r|
              el.version_field == r[:version] &&
                el.component_type == r[:component_type] &&
                (el.namespace.nil? || el.namespace == r[:namespace])
            end
            if matches.empty?
              unmatched << el
            elsif matches.size == 1
              ret << matches.first
            else
              if base_match = base_module_local_params && match_base_module?(matches, base_module_local_params)
                ret << base_match
              else
                # TODO: may put in logic that sees if one is service modules ns and uses that one when multiple matches
                module_name = Component.module_name(el.component_type)
                error_params = {
                  module_type: 'component',
                  module_name: Component.module_name(el.component_type),
                  namespaces: matches.map { |m| m[:namespace] }.compact # compact just to be safe
                }
                fail ServiceModule::ParsingError::AmbiguousModuleRef, error_params
              end
            end
          end
          unless unmatched.empty?
            # TODO: indicate whether there is a nailed namespace that does not exist or no matches at all
            cmp_refs = unmatched.map do |match_el|
              cmp_type = match_el.component_type
              if ns = match_el.namespace
                cmp_type = "#{ns}:#{cmp_type}"
              end
              {
                component_type: cmp_type,
                version: match_el.version
              }
            end
            if opts[:service_instance_module]
              fail ServiceModule::ParsingError::RemovedServiceInstanceCmpRef.new(cmp_refs, opts)
            else
              fail ServiceModule::ParsingError::DanglingComponentRefs.new(cmp_refs, opts)
            end
          end
          ret
        end
      end

      private

      def match_base_module?(matches, base_module_local_params)
        namespace = base_module_local_params.namespace
        version   = base_module_local_params.version
        matches.find { |match| match[:namespace] == namespace and match[:version] = version }
      end
    end
  end
end
