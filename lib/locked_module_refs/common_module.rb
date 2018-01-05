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
  class LockedModuleRefs
    class CommonModule < self
      require_relative('common_module/parse')
      require_relative('common_module/update')
      require_relative('common_module/matching_templates')

      include Update::Mixin

      attr_reader :parent

      # opts can have keys:
      #   :content_hash_form_is_reified
      def initialize(parent, content_hash_form, opts = {})
        super(ret_indexd_elements(parent, content_hash_form, opts))
        @parent = parent
      end
      private :initialize

      def self.update_module_refs(module_branch, input_module_refs)
        existing_module_refs = get_module_refs(module_branch)
        existing_module_refs.update_module_refs_if_needed!(input_module_refs)
      end

      def update_module_refs_if_needed!(input_module_refs)
        # The call 'update_object_if_needed!' updates the object module_refs and returns true if changed
        # The call 'existing_module_refs.update' updates the object model
        update if update_object_if_needed!(input_module_refs)
        self
      end

      def self.get_dependent_modules(service_instance_branch)
        ModuleRef.get_component_module_ref_array(service_instance_branch)
      end

      def self.get_dependent_module_refs(service_instance_branch)      
        content_hash_content = ModuleRef.get_component_module_ref_array(service_instance_branch).inject({}) do |h, r|
          h.merge(key(r[:module_name]) => r)
        end
        new(service_instance_branch, content_hash_content)
      end

      # TODO: DTK-3366; integrate get_dependent_module_refs and get_module_refs
      def self.get_module_refs(module_branch)
        common_module_branch = module_branch.common_module_branch

        content_hash_content = ModuleRef.get_component_module_ref_array(common_module_branch).inject({}) do |h, r|
          h.merge(key(r[:module_name]) => r)
        end
        
        # TODO: DTK-3366: see if we still need below
        content_hash_content.each do |k, v|
          v[:version_info] = nil if v[:version_info] == 'master'
        end
        
        new(common_module_branch, content_hash_content)
      end
      
      # component refs are augmented with :component_template key which points to
      # associated component template or nil
      # opts can have keys
      #   :raise_if_missing_dependencies
      #   :module_local_params
      #   :donot_set_component_templates
      #   :set_namespace
      #   :force_compute_template_id
      def set_matching_component_template_info?(aug_cmp_refs, opts = {})
        MatchingTemplates.set_matching_component_template_info?(self, aug_cmp_refs, opts)
        aug_cmp_refs
      end

      private

      # opts can have keys:
      #   :content_hash_form_is_reified
      def ret_indexd_elements(parent, content_hash_form, opts = {})
        opts[:content_hash_form_is_reified] ?
        content_hash_form :
          Parse.reify_content(parent.model_handle(:model_ref), content_hash_form)
      end

    end
  end
end
