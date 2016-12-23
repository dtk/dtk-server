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
  class CommonModule::Update::Module::Info
    class Service < self
      
      def initialize(*args)
        service_instance_opts = args.pop
        super(*args)
        @component_info_exists = service_instance_opts[:component_info_exists]
      end

      # returns true if there is service info
      def create_or_update_from_parsed_common_module?
        if parsed_assemblies = parsed_common_module.val(:Assemblies)
          service_module_branch = create_module_branch_and_repo?
          CommonDSL::Parse.set_dsl_version!(service_module_branch, parsed_common_module)
          if parsed_dependent_modules = parsed_common_module.val(:DependentModules)
            update_component_module_refs(service_module_branch, parsed_dependent_modules, omit_base_reference: @component_info_exists)
          end
          CommonModule::ServiceInfo.update_assemblies_from_parsed_common_module(project, service_module_branch, parsed_assemblies, local_params)
          true
        end
      end

      private

      def module_type
        :service_module
      end

    end
  end
end
