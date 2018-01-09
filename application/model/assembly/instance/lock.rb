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
    class Lock < Model
      attr_accessor :assembly_instance, :service_module_name, :service_module_namespace, :service_module_sha
      # opts can have keys:
      #   :version
      def self.create(assembly_instance, service_module, opts = {})
        assembly_instance_lock = create_stub(assembly_instance.model_handle(:assembly_instance_lock))
        assembly_instance_lock.set_and_save_object!(assembly_instance, service_module, version: opts[:version])
      end
      
      def self.get(assembly_instance)
        sp_hash = {
          cols: self.common_columns,
          filter: [:eq, :component_id, assembly_instance.id]
        }
        Model.get_obj(assembly_instance.model_handle(:assembly_instance_lock), sp_hash)
      end

      def set_and_save_object!(assembly_instance, service_module, opts = {})
        set_object!(assembly_instance, service_module, opts)
        save_to_model
        self
      end
      
      private
      
      # opts can have keys: 
      #   :version
      def set_object!(assembly_instance, service_module, opts = {})
        module_branch =
          if opts[:version]
            service_module.get_module_branch_matching_version(opts[:version])
          else
            service_module.get_augmented_module_branch
          end
        @assembly_instance        = assembly_instance
        @service_module_name      = service_module[:display_name]
        @service_module_namespace = service_module.module_namespace
        @service_module_sha       = module_branch.get_field?(:current_sha)
        save_to_model
        self
      end

      def save_to_model
        db_update_hash = DBUpdateHash.new
        hash_body = {
          display_name: self.assembly_instance.display_name,
          module_name: self.service_module_name,
          module_namespace: self.service_module_namespace,
          service_module_sha: self.service_module_sha,
          created_at: Aux.now_time_stamp
        }
        hash = { self.assembly_instance.display_name => hash_body }
        db_update_hash.merge!(hash)
        db_update_hash.mark_as_complete
        assembly_instance_idh = self.assembly_instance.id_handle
        Model.input_hash_content_into_model(assembly_instance_idh, assembly_instance_lock: db_update_hash)
        self
      end
      
      def self.common_columns
        [:id, :display_name, :group_id, :module_name, :module_namespace, :service_module_sha, :created_at]
      end
      
    end
  end
end
