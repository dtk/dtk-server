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
      module ClassMixin
        def get_matching_elements(project_idh, match_element_array, opts = {})
          module_type = (opts[:service_instance_module] ? :service_instance  : :module)
          matched, unmatched = MatchElement.find_matched_and_unmatached(project_idh, match_element_array, opts)
          MatchElement.raise_error_when_unmatched_elements(unmatched, module_type, opts) unless unmatched.empty?
          matched
        end
      end
      
      def initialize(hash_params)
        super()
        replace(hash_params)
      end
      def component_type
        self[:component_type]
      end
      def namespace
        self[:namespace]
      end
      def version_field
        self[:version_field]
      end
      def version
        self[:version]
      end
      
      # returns [matched, unmatched]
      def self.find_matched_and_unmatached(project_idh, match_element_array, opts = {})
        matched   = []
        unmatched = []
        component_rows = get_components(project_idh, match_element_array)
        match_element_array.each { |el| el.update_matched_and_unmatched!(matched, unmatched, component_rows, opts) }
        [matched, unmatched]
      end

      # returns [matched, unmatched]
      def update_matched_and_unmatched!(matched, unmatched, component_rows, opts) 
        matches = component_rows.select do |r|
          version_field == r[:version] and component_type == r[:component_type] and (namespace.nil? || namespace == r[:namespace])
        end
        case matches.size
        when 0
          unmatched << self
        when 1
          matched << matches.first
        else # size > 2
          base_module_local_params = opts[:module_local_params]
          if base_match = base_module_local_params && match_base_module?(matches, base_module_local_params)
            matched << base_match
          else
            raise_error_ambiguous_module_ref
          end
        end
      end

      def raise_error_ambiguous_module_ref
        # TODO: may put in logic that sees if one is service modules ns and uses that one when multiple matches
        module_name = Component.module_name(component_type)
        error_params = {
          module_type: 'component',
          module_name: Component.module_name(component_type),
          namespaces: matches.map { |m| m[:namespace] }.compact # compact just to be safe
        }
        fail parsing_error_class::AmbiguousModuleRef, error_params
      end
      
      def self.raise_error_when_unmatched_elements(unmatched, module_type, opts = {})
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
        case module_type
        when :service_instance
          fail parsing_error_class::RemovedServiceInstanceCmpRef.new(cmp_refs, opts)
        when :module
          fail parsing_error_class::DanglingComponentRefs.new(cmp_refs, opts)
        else
          fail Error, "Bad module_type '#{module_type}'"
        end
        
      end
      
      private
      
      def self.get_components(project_idh, match_element_array)
        cmp_types = match_element_array.map(&:component_type).uniq
        versions  = match_element_array.map(&:version_field)
        
        sp_hash = {
          cols: [:id, :group_id, :component_type, :version, :implementation_id, :external_ref],
          filter: [:and,
                   [:eq, :project_project_id, project_idh.get_id],
                   [:oneof, :version, versions],
                   [:eq, :assembly_id, nil],
                   [:eq, :node_node_id, nil],
                   [:oneof, :component_type, cmp_types]]
        }
        Component::Template.augment_with_namespace!(Component::Template.get_objs(project_idh.createMH(:component), sp_hash))
      end
      
      
      def self.match_base_module?(matches, base_module_local_params)
        namespace = base_module_local_params.namespace
        version   = base_module_local_params.version
        matches.find { |match| match[:namespace] == namespace and match[:version] = version }
      end

      def self.parsing_error_class
        ServiceModule::ParsingError
      end
      def parsing_error_class
        self.class.parsing_error_class
      end

    end
  end
end
