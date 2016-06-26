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
  module CommonModule::DSL
    class DirectoryParser
      class Git < self
        def initialize(file_types, module_branch)
          @file_types    = file_types.kind_of?(Array) ? file_types : [file_types]
          @module_branch = module_branch
        end

        def matching_file_obj?(opts = {})
          ret = nil
          [:file_path, :dir_path].each do |key|
            fail Error, "Treatment of option :#{key} is not yet supported" if opts[key]
          end
          files = list_files_in_repo
          @file_types.each do |file_type|
            files.each do |file_path|
              if file_type.matches?(file_path, exact: true)
                return FileObj.new(file_type, file_path, file_parser: FileParser, content: get_file_content(file_path))
              end
            end
          end
          ret
        end
        
        private

        def list_files_in_repo
          RepoManager.ls_r(ls_r_depth(@file_types), { file_only: true }, @module_branch)
        end

        def get_file_content(file_path)
          RepoManager.get_file_content(file_path, @module_branch)
        end

        def ls_r_depth(_file_types)
          # By setting this to nil, we haev simple strategy where RepoManager.ls_r returns all files
          # More sophisticated would be to look at @file_types patterns to find what could be maximum depth
          nil
        end
      end
    end
  end
end
