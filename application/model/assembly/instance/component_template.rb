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
  class Assembly::Instance
    module ComponentTemplateMixin
      def find_matching_aug_component_template?(component_type, component_module_refs)
        find_matching_aug_component_template(component_type, component_module_refs, donot_raise_error: true)
      end

      # opts can have keys:
      #   :donot_raise_error
      def find_matching_aug_component_template(component_type, component_module_refs, opts = {})
        module_name = Component.module_name(component_type)
        unless matching_module_ref = component_module_refs.component_module_ref?(module_name)
          return nil if opts[:donot_raise_error]
          fail ErrorUsage, "Cannot find dependency for component #{Component.display_name_print_form(component_type)}'s module '#{module_name}' in the dependency section"
        end
        
        namespace = matching_module_ref.namespace
        version   =  matching_module_ref.version_string
        
        matches = find_matching_aug_component_templates(component_type, namespace, version: version)
        if matches.size == 1
          matches.first
        elsif matches.size > 1
          return nil if opts[:donot_raise_error]
          fail Error, "Unexpected that multiple matches: #{matches.inspect}" 
        else
          return nil if opts[:donot_raise_error]
          fail ErrorUsage, "Component '#{Component.display_name_print_form(component_type)}' is not in dependent module '#{matching_module_ref.print_form}'"
        end
      end

      # This method returns an array with zero or more matching augmented component templates
      # opts can have keys
      #   :version
      #   :use_just_base_template
      def find_matching_aug_component_templates(component_type, namespace, opts = {})
        ret = []
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
        ret = Component::Template.get_objs(model_handle(:component_template), sp_hash, keep_ref_cols: true).select do |cmp| 
          cmp[:namespace][:display_name] == namespace 
        end
        return ret if ret.empty?

        # there could be two matches one from base template and one from service insatnce specific template; in
        # this case use service specfic one
        if !opts[:use_just_base_template] and ret.find { |cmp| cmp[:version] == assembly_version }
          ret.select! { |cmp| cmp[:version] == assembly_version }
        end
        
        ret
      end

    end
  end
end
