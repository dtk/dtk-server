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
  class CommonModule::Update::NestedModule
    module UpdateModuleRefs
      module Mixin

        def update_module_refs
          LockedModuleRefs::CommonModule.update_module_refs(self.module_branch, self.module_refs_hash)
        end
        
        protected
      
        def module_refs_hash
          @module_refs_hash ||= ret_module_refs_hash
        end
        
        private
        
        def ret_module_refs_hash
          (self.parsed_dependent_modules || []).map { |parsed_module_ref| module_ref_hash_form(parsed_module_ref) }
        end
        
        def  module_ref_hash_form(parsed_module_ref)
          { 
            display_name: parsed_module_ref.req(:ModuleName),
            namespace_name: parsed_module_ref.req(:Namespace), 
            version_info: parsed_module_ref.val(:ModuleVersion)
          }
        end
      end
    end
  end
end
