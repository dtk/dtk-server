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
  module CommonDSL::Generate
    class DirectoryGenerator
      class Git < self
        # opts can keys:
        #  :module_branch
        #     or
        #  :repo_dir
        #  :branch_name
        def initialize(opts = {})
          @repo_manger_context = ret_repo_manger_context(opts)
        end

        def add_file?(file_path, file_content, opts = {})
          if any_changes = RepoManager.add_file(file_path, file_content, opts[:commit_msg], @repo_manger_context)
            RepoManager.push_changes(@repo_manger_context) unless opts[:donot_push_changes]
          end
          any_changes
        end

        def add_files(file_path__content_array, opts = {})
          if any_changes = RepoManager.add_files(@repo_manger_context, file_path__content_array, opts)
            RepoManager.push_changes(@repo_manger_context) unless opts[:donot_push_changes]
          end
          any_changes
        end

        def add_remote_files(add_remote_files_info)
          RepoManager.add_remote_files(add_remote_files_info, @repo_manger_context)
        end

        private

        def ret_repo_manger_context(opts)
          if opts[:module_branch]
            opts[:module_branch] 
          elsif opts[:repo_dir] and opts[:branch_name]
            { repo_dir: opts[:repo_dir], branch: opts[:branch_name] }
          else
            fail Error, "Either opts[:module_branch] or (opts[:repo_dir] and opts[:branch_name]) must be non nil"
          end
        end

      end
    end
  end
end
