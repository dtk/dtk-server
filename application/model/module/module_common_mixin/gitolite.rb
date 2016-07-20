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
#
# All interaction that streamlines interaction with gitolite for modules should be inserted here. Main purpose is grouping
# logic for gitolite interaction in here.
#

module DTK
  module ModuleCommonMixin
    module Gitolite
      def repo_file_content(module_branch, rel_file_path)
        repo_full_path, branch = RepoManager.repo_full_path_and_branch(module_branch)
        dir_parser = ::DtkCommon::DSL::DirectoryParser::Git.new(self.module_type(), repo_full_path, branch)
        file_content = dir_parser.file_content(rel_file_path)
      end
    end
  end
end
