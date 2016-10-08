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
  class RepoManager
    class AddRemoteFilesInfo
      class GitSubtree < self
        def initialize
          @git_subtree_info_array = []
        end
        
        def add_git_subtree_info!(prefix, external_repo, external_branch)
          @git_subtree_info_array << GitSubtreeInfo.new(prefix, external_repo, external_branch)
          self
        end
        
        def git_add_needed?
          false
        end
        
        private

        GitSubtreeInfo = Struct.new(:prefix, :external_repo, :external_branch)
        
        def add_files_git_repo_manager(git_repo_manager)
          # TODO: stub
        end
        
      end
    end
  end
end
