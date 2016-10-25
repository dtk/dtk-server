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
  module CommonDSL::NestedModuleRepoSync
    # Methods to transform to and from component module form
    module ComponentModuleTransform
      def self.transform_from_component_module_form(service_module_branch, aug_nested_module_branches)
        aug_nested_module_branches.each do |aug_nested_module_branch|
          dsl_file_input_hash = ModuleDSL.get_dsl_file_input_hash(aug_nested_module_branch.implementation)
          module_refs         = ModuleRefs.get_component_module_refs(aug_nested_module_branch)
          transform_to_service_instance_dsl(dsl_file_input_hash, module_refs)
        end
        # add and commit
      end

      private
      
      def self.transform_to_service_instance_dsl(dsl_file_input_hash, module_refs)
        # TODO: stub
        pp [:transform_from_component_module_for, dsl_file_input_hash, module_refs]
        # TODO: ModuleDSL.get_module)refs_hash
      end
        
    end
  end
end
