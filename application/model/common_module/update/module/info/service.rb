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
      require_relative('service/transform')
      
      def initialize(*args)
        service_instance_opts = args.pop
        super(*args)
        @component_defs_exist = service_instance_opts[:component_defs_exist]
      end

      def create_or_update_from_parsed_common_module?
        if parsed_assemblies = self.parsed_assemblies
          CommonDSL::Parse.set_dsl_version!(self.service_module_branch, self.parsed_common_module)
          update_component_module_refs(self.service_module_branch, self.parsed_dependent_modules, omit_base_reference: component_defs_exist?, add_recursive_dependencies: true)

          # update assemblies before updating module refs because we need to check for references in assemblies when updating module refs
          CommonModule::Info::Service.update_assemblies_from_parsed_common_module(self.project, self.service_module_branch, parsed_assemblies, local_params, raise_if_missing_dependencies: true)

          delete_component_module_refs?(self.service_module_branch, self.parsed_dependent_modules, omit_base_reference: component_defs_exist?)
        end
      end

      def transform_from_common_module?
        transform = Transform.new(self.parsed_common_module, self).compute_service_module_outputs!
        file_path__content_array = transform.file_path__content_array
      end

      def check_for_missing_dependencies
        CommonDSL::Parse.set_dsl_version!(self.service_module_branch, self.parsed_common_module)
        check_and_ret_missing_modules(self.service_module_branch, self.parsed_dependent_modules, omit_base_reference: component_defs_exist?)
      end

      protected

      def component_defs_exist?
        @component_defs_exist
      end

      def service_module_branch
        @service_module_branch ||= create_module_and_branch?
      end

      def module_type
        :service_module
      end

    end
  end
end
