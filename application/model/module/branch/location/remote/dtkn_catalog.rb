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
module DTK; class ModuleBranch; class Location
  class Remote
    class DTKNCatalog < RemoteParams::DTKNCatalog
      include RemoteMixin

      def get_linked_workspace_branch_obj?(module_obj)
        filter = {
          version: version,
          remote_namespace: namespace
        }
        module_obj.get_augmented_module_branch(filter: filter)
      end

      private

      def ret_repo_url
        RepoManagerClient.repo_url_ssh_access(repo_name())
      end

      def ret_remote_ref
        "#{remote_repo_base}--#{namespace}"
      end

      def ret_branch_name
        if version.nil? || version == HeadBranchName
          HeadBranchName
        else
          "v#{version}"
        end
      end
      HeadBranchName = 'master'
    end
  end
end; end; end