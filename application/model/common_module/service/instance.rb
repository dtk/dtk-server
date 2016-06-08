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
module DTK; module CommonModule
  module Service
    class Instance < AssemblyModule::Service
      def self.create_repo(assembly_instance)
        new(assembly_instance).create_repo
      end

      def create_repo
        module_branch = get_or_create_service_instance_branch
        ModuleRepoInfo.new(module_branch)
      end

      private

      def get_or_create_service_instance_branch
        # TODO: DTK-2445: to co-exist with assembly_module form should we choose a different branch name
        # The method get_or_create_assembly_branch uses the name that assembly_module does
        get_or_create_assembly_branch
      end
    end
  end
end; end
