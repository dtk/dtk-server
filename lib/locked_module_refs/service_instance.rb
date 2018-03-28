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
    class ServiceInstance < self
      # require_relative('service_instance/element')

      def self.create_from_common_module_refs(base_module_branch, new_service_instance_module_branch)
        base_module_refs = CommonModule.get_module_refs(base_module_branch)
        ModuleRef.create_or_update(new_service_instance_module_branch, base_module_refs.module_refs_array)
        # TODO: DTK-3366: also do do Element.create_or_update(new_service_instance_module_branch, base_module_refs.module_refs_array)
      end
    end
  end
end
