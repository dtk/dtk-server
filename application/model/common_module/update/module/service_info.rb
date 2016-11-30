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
  class CommonModule::Update::Module
    class ServiceInfo < self
      def create_or_update_from_parsed_common_module?
        # TODO: DTK-2766: see if should create module_branch if no assemblies
        module_branch = create_or_ret_module_branch
        CommonDSL::Parse.set_dsl_version!(module_branch, parsed_common_module)

        # TODO: this might be done in parent since relates to both componenta dn service info
        update_component_module_refs_from_parsed_common_module(module_branch)

        CommonModule::ServiceInfo.update_assemblies_from_parsed_common_module(project, module_branch, parsed_common_module)
      end

      private

      def module_type
        :service_module
      end
      # TODO: remove if not used
      # def service_info_remote_name
      #  RepoManager::Constant.service_info_remote_name
      # end
      
    end
  end
end
