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
        def initialize(file_type, module_branch)
          @file_type     = file_type
          @module_branch = module_branch
        end
        def add_file?(file_content, opts = {})
          if any_changes = RepoManager.add_file(@file_type.canonical_path, file_content, opts[:commit_msg], @module_branch)
            unless opts[:donot_push_changes]
              RepoManager.push_changes(@module_branch)
            end
          end
        end

      end
    end
  end
end
