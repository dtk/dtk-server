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
    # Top level abstract class to provide instances that inidcate how to add files to a repo
    # Currently implemnted is adding fils by copying from a source. This can be extended to include
    # methods such as using git sub-trees or submodules
    class AddRemoteFilesInfo
      require_relative('add_remote_files_info/copy')
      require_relative('add_remote_files_info/git_subtree')

      def add_files(opts = {})
        if git_repo_manager = opts[:git_repo_manager]
          add_files_git_repo_manager(git_repo_manager)
        else
          fail Error, "Unexpected args in opts"
        end
      end

      def git_add_needed?
        fail Error::NoMethodForConcreteClass.new(self.class)
      end

      private

      def add_files_git_repo_manager(_git_repo_manager)
        fail Error::NoMethodForConcreteClass.new(self.class)
      end

    end
  end
end
