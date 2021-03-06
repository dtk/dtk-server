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
module DTK; class ModuleRef
  class Lock
    module Persist
      def self.create_or_update(module_refs_lock)
        db_update_hash = db_update_hash_all_elements(module_refs_lock)
        db_update_hash.mark_as_complete()
        assembly_instance_idh = module_refs_lock.assembly_instance.id_handle()
        Model.input_hash_content_into_model(assembly_instance_idh, module_ref_lock: db_update_hash)
        module_refs_lock
      end

      def self.get(assembly_instance)
        sp_hash = {
          cols: Lock.common_columns(),
          filter: [:eq, :component_component_id, assembly_instance.id]
        }
        Model.get_objs(assembly_instance.model_handle(:module_ref_lock), sp_hash)
      end

      private

      def self.db_update_hash_all_elements(module_refs_lock)
        ret = DBUpdateHash.new()
        module_refs_lock.each_pair do |module_name, module_ref_lock|
          if hash = module_ref_lock_hash_form(module_name, module_ref_lock)
            ret.merge!(hash)
          end
        end
        ret
      end

      def self.module_ref_lock_hash_form(module_name, module_ref_lock)
        unless info = module_ref_lock.info
          raise_persistence_error('No Info object found on object', module_ref_lock)
        end
        hash_body = {
          display_name: module_name,
          module_name: module_name,
          info: info.hash_form(),
          locked_branch_sha: module_ref_lock.locked_branch_sha
        }
        { module_name => hash_body }
      end

      def self.raise_persistence_error(msg, module_ref_lock)
        unless msg =~ /:$/
           msg += ':'
        end
        Log.error_pp([msg, module_ref_lock])
      end
    end
  end
end; end