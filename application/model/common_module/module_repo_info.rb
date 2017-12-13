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
  class CommonModule
    class ModuleRepoInfo < ::Hash
      # opts can have keys:
      #  :ret_remote_info
      def initialize(module_branch, opts = {})
        module_obj = module_branch.get_module
        hash = {
          module: {
            id: module_obj.id,
            name: module_obj.module_name,
            namespace: module_obj.module_namespace,
            version: module_branch.get_field?(:version)
          }
        }
        
        if repo = module_branch.get_repo(:repo_name)
          repo_name = repo.get_field?(:repo_name)
          repo_info = {
            id: repo.id,
            name: repo_name,
            url: RepoManager.repo_url(repo_name)
          }

          branch_info = {
            name: module_branch.get_field?(:branch),
            head_sha: RepoManager.branch_head_sha(module_branch)
          }

          hash.merge!(repo: repo_info, branch: branch_info)
          hash.merge!(has_remote: true) if repo.default_remote
        end
        

        replace(hash)
      end
    end
  end
end
