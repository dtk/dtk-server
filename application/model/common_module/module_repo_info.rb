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
    # TODO: DTK-2587: ModuleRepoInfo with replace Dtk::ModuleRepoInfo
    class ModuleRepoInfo < ::Hash
      def initialize(module_branch)
        dtk_module_branch_info =  module_branch.get_module_repo_info
        replace(convert_from_dtk_module_branch_info(dtk_module_branch_info))
      end

      private

      def convert_from_dtk_module_branch_info(dtk_module_branch_info)
        dtk_info = dtk_module_branch_info
        {
          repo: {
            id: dtk_info[:repo_id],
            name: dtk_info[:repo_name],
            url: dtk_info[:repo_url]
          },
          module: {
            id: dtk_info[:module_id],
            name: dtk_info[:module_name],
            namespace: dtk_info[:module_namespace]
          },
          branch: {
            name: dtk_info[:workspace_branch],
            head_sha: dtk_info[:branch_head_sha]
          }
        }
      end
    end
  end
end
