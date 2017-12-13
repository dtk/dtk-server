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
        def self.workspace_branch_name(project, version = nil, opts = {})
          ret_branch_name(project, version, opts)
        end

        def self.private_user_repo_name(username, module_type, module_name, module_namespace)
          common_module_full_name(base_repo_name(username, module_name, module_namespace))
        end

        def self.private_user_repo_display_name(username, module_type, module_name, module_namespace)
          "#{module_type}-#{base_repo_name(username, module_name, module_namespace)}"
        end

        private

        def self.base_repo_name(username, module_name, module_namespace)
          "#{username}-#{module_namespace}-#{module_name}"
        end

        def self.common_module_full_name(repo_name)
          "m-#{repo_name}"
        end

        def ret_branch_name(opts = {})
          self.class.ret_branch_name(@project, version, opts)
        end

        def ret_private_user_repo_name
          username = CurrentSession.new.get_username
          namespace_name = module_namespace_name || Namespace.default_namespace_name
          Local.private_user_repo_name(username, module_type, module_name, namespace_name)
        end

        def ret_private_user_repo_display_name
          username = CurrentSession.new.get_username
          namespace_name = module_namespace_name || Namespace.default_namespace_name
          Local.private_user_repo_display_name(username, module_type, module_name, namespace_name)
        end

        #===== helper methods

        def self.ret_branch_name(project, version, opts = {})
          # user_prefix = "workspace-#{project.get_field?(:ref)}"
          user_prefix = opts[:version_branch]||"workspace-#{project.get_field?(:ref)}"
          if version.is_a?(ModuleVersion::AssemblyModule)
            assembly_suffix = "--assembly-#{version.assembly_name}"
            "#{user_prefix}#{assembly_suffix}"
          else
            version_suffix = ((version && version != BranchNames::VersionFieldDefault) ? "-v#{version}" : '')
            "#{user_prefix}#{version_suffix}"
          end
        end
      end
    end
  end
end; end
