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
    class Augmented < self
      subclass_model :component_template_augmented, :component, print_form: 'component_template_augmented'

      def version
        self[:version] || raise_error_missing(:version)
      end
      def module_branch
        self[:module_branch] || raise_error_missing(:module_branch)
      end
      def component_module
        self[:component_module] || raise_error_missing(:component_module)
      end
      def namespace_name
        (self[:namespace] && self[:namespace].display_name) || raise_error_missing(:namespace)
      end

      def self.find_matching_component_template(assembly_instance, component_type, component_module_refs, opts = {})
        module_name = Component.module_name(component_type)

        namespace, version = find_namespace_and_version?(module_name, component_module_refs, dependent_modules: opts[:dependent_modules])

        if namespace.nil?
          return nil if opts[:donot_raise_error]
          fail ErrorUsage, "Cannot find dependency for component #{Component.display_name_print_form(component_type)}'s module '#{module_name}' in the dependency section" 
        end

        matches = find_matching_component_templates(assembly_instance, component_type, namespace, version: version)
        if matches.size == 1
          matches.first
        elsif matches.size > 1
          return nil if opts[:donot_raise_error]
          fail Error, "Unexpected that multiple matches: #{matches.inspect}" 
        else
          return nil if opts[:donot_raise_error]
          # this is temporary solution until we implement dependency diffs functionality
          # ref_print_form = matching_module_ref ? matching_module_ref.print_form : "#{namespace}:#{module_name}(#{version})"
          ref_print_form = "#{namespace}:#{module_name}(#{version})"
          # fail ErrorUsage, "Component '#{Component.display_name_print_form(component_type)}' is not in dependent module '#{matching_module_ref.print_form}'"
          fail ErrorUsage, "Dependent module '#{ref_print_form}' not found! Please check if provided namespace and/or version are correct and try again"
        end
      end

      # This method returns an array with zero or more matching augmented component templates
      # opts can have keys
      #   :version
      #   :use_just_base_template
      def self.find_matching_component_templates(assembly_instance, component_type, namespace, opts = {})
        ret = []
        assembly_version  = assembly_instance.assembly_version
        versions_to_match = [opts[:version] ? opts[:version].gsub(/\(|\)/,'') : 'master']
        versions_to_match << assembly_version unless opts[:use_just_base_template]
        
        sp_hash = {
          cols: [:id, :group_id, :display_name, :module_branch_id, :type, :ref, :augmented_with_module_info, :version],
          filter: [:and,
                   [:eq, :type, 'template'],
                   [:eq, :component_type, component_type],
                   [:neq, :project_project_id, nil],
                   [:oneof, :version, versions_to_match],
                   [:eq, :node_node_id, nil]]
        }
        
        ret = Model.get_objs(assembly_instance.model_handle(:component), sp_hash, keep_ref_cols: true).map do |component| 
          create_augmented_component_template(component) 
        end.select { |aug_cmp_template| aug_cmp_template.namespace_name == namespace }

        return ret if ret.empty?

        # there could be two matches one from base template and one from service insatnce specific template; in
        # this case use service specfic one
        if !opts[:use_just_base_template] and ret.find { |aug_cmp_template| aug_cmp_template.version == assembly_version }
          ret.select! { |aug_cmp_template| aug_cmp_template.version == assembly_version }
        end
        
        ret
      end

      private

      def self.create_augmented_component_template(component)
        component.id_handle.create_object(model_name: :component_template_augmented).merge(component)
      end

      # opts can have keys:
      #   :dependent_modules
      # returns [namespace, version] can be nil
      def self.find_namespace_and_version?(module_name, component_module_refs, opts = {})
        if matching_module_ref = component_module_refs.component_module_ref?(module_name)
          [matching_module_ref.namespace, matching_module_ref.version_string]
        else
          # TODO: this is temporary solution until we implement dependency diffs functionality
          if dependent_modules = opts[:dependent_modules]
            if matching_module = find_in_dependent_modules(dependent_modules, module_name)
              [matching_module[:namespace], matching_module[:version]]
            end
          end
        end
      end

      # opts can have keys:
      #   :dependent_modules
      def self.find_in_dependent_modules(dependent_modules, module_name)
        matching_modules = dependent_modules.select{ |name, _version| ((name.split('/')[1])||'') == module_name }
        if matching_modules.empty?
          fail ErrorUsage, "Dependency module '#{module_name}' not found in 'dependencies' list!"
        elsif matching_modules.size > 1
          fail ErrorUsage, "Unexpected that multiple matches found for module '#{module_name}' in 'dependencies' list!"
        else
          namespace_name  = matching_modules.keys.first
          version         = matching_modules[namespace_name]
          namespace, name = namespace_name.split('/')
          {
            namespace: namespace,
            name: name,
            version: version
          }
        end
      end

      def raise_error_missing(field)
        fail Error, "Unexpected that augmented component templaet with id #{id} is missing field '#{field}'"
      end

    end
  end
end
