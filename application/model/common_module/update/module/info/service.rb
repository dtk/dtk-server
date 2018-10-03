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
      # opts can have keys:
      #   :parse_needed
      #   :diffs_summary
      #   :initial_update
      def initialize(parent, opts = {})
        super
        @component_defs_exist = opts[:component_defs_exist]
      end

      def create_or_update_from_parsed_common_module?
        create_or_update_from_parsed_common_module(parsed_assemblies || [])
      end

      def transform_from_common_module?
        fail 'got here'
        transform = Transform.new(self.parsed_common_module, self).compute_service_module_outputs!
        file_path__content_array = transform.file_path__content_array
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

      def import_helper
        @import_helper ||= ret_import_helper
      end

      private

      def create_or_update_from_parsed_common_module(parsed_assemblies)
        CommonDSL::Parse.set_dsl_version!(self.service_module_branch, self.parsed_common_module)
        self.service_module_branch.set_dsl_parsed!(false)

        self.import_helper.put_needed_info_into_import_helper!(parsed_assemblies, self.local_params, raise_if_missing_dependencies: true)
        self.import_helper.import_into_model

        self.service_module_branch.set_dsl_parsed!(true)
      end

      def ret_import_helper
        service_module = CommonModule::Info::Service.get_base_service_module(self.service_module_branch)
        Import::ServiceModule.new(self.project, service_module, self.service_module_branch)
      end

    end
  end
end
