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
    class ModuleRefSha < Model
      def self.create_for_base_module(assembly_instance, aug_base_module_branch)
        create(assembly_instance, aug_base_module_branch)
      end
      
      def self.create_for_nested_module(assembly_instance, aug_nested_module_branch)
        create(assembly_instance, aug_nested_module_branch)
      end

      def self.get_for_base_and_nested_modules(assembly_instance)      
        matching_module_refs_shas(assembly_instance)
      end

      def self.get_for_base_module(assembly_instance)      
        # One way to do this is to add another field to object to designate
        fail "TODO: DCTK-3366: need to write; it can call matching_module_refs_shas but needs to pick out base module branch"
      end

      private
      
      def self.create(assembly_instance, aug_module_branch)
        create_from_row(model_handle(assembly_instance), hash_content(assembly_instance, aug_module_branch), ret_obj:  { model_name: model_name })
      end

      def self.hash_content(assembly_instance, aug_nested_module_branch)
        key       = "#{assembly_instance.display_name}-#{aug_nested_module_branch.id}"
        repo_name = aug_nested_module_branch.get_field(:repo)[:repo_name] || fail(Error, "Unexpected that key [:repo][:repo_name] is nil")
        {
          display_name: key,
          ref: key,
          component_component_id: assembly_instance.id,
          module_branch_id: aug_nested_module_branch.id,
          sha: aug_nested_module_branch.get_field(:current_sha),
          repo_name: repo_name,
          branch_name: aug_nested_module_branch.get_field(:branch),
          module_name: aug_nested_module_branch.get_field(:module_name)
        }
      end
      
      def self.matching_module_refs_shas(assembly_instance)
        sp_hash = {
          cols: common_columns,
          filter: [:eq, :component_component_id, assembly_instance.id]
        }
        get_objs(model_handle(assembly_instance), sp_hash)
      end
      
      def self.common_columns
        [:id, :display_name, :group_id, :sha, :component_component_id, :module_branch_id, :repo_name, :branch_name]
      end
      
      def self.model_name
        :assembly_instance_module_ref_sha
      end
        
      def self.model_handle(assembly_instance)
        assembly_instance.model_handle.create_childMH(model_name)
      end
    end
  end
end

=begin
    def self.create_or_update(module_refs_lock)
      Persist.create_or_update(module_refs_lock)
    end
    
    def self.get(assembly_instance)
      Persist.get(assembly_instance).map(&:reify)
    end
=end
