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
module DTK; class ModuleBranch
  class Location
    class Server < self
      def initialize(project, local_params = nil, remote_params = nil)
        super
      end
      class Local < Location::Local
        def self.workspace_branch_name(project, version = nil)
          ret_branch_name(project, version)
        end

        def self.repo_name(module_type, module_name, module_namespace)
          common_module_full_name(base_repo_name(module_name, module_namespace))
        end

        def self.repo_display_name(module_type, module_name, module_namespace)
          "#{module_type}-#{base_repo_name(module_name, module_namespace)}"
        end

        private

        def self.base_repo_name(module_name, module_namespace)
          "#{module_namespace}-#{module_name}"
        end

        def self.common_module_full_name(repo_name)
          repo_name
        end

        def ret_branch_name
          self.class.ret_branch_name(self.project, version)
        end

        def ret_repo_name
          namespace_name = module_namespace_name || Namespace.default_namespace_name
          Local.repo_name(module_type, module_name, namespace_name)
        end

        def ret_repo_display_name
          namespace_name = module_namespace_name || Namespace.default_namespace_name
          Local.repo_display_name(module_type, module_name, namespace_name)
        end

        ASSEMBLY_MODULE_PREFIX = 'service_instance'
        DEFAULT_MODULE_BRANCH  = 'master'

        def self.ret_branch_name(project, version)
          if version.is_a?(ModuleVersion::AssemblyModule)
            "#{ASSEMBLY_MODULE_PREFIX}--#{version.assembly_name}"
          else
            (version && version != BranchNames::VersionFieldDefault) ? "-v#{version}" : DEFAULT_MODULE_BRANCH
          end
        end
      end
    end
  end
end; end
