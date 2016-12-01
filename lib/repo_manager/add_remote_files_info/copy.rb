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
require 'fileutils'
module DTK
  class RepoManager
    class AddRemoteFilesInfo
      class Copy < self
        # opts can have keys
        #  :source_dir - absolute path
        #  :target_dir - relative path; default is '.'
        def initialize(opts = {})
          @source_target_pairs = opts[:source_dir] ? [source_target_dir_pair(opts[:source_dir], opts[:target_dir])] : []
        end
        
        def add_source_target_dir_pair!(source_dir, target_dir = nil)
          @source_target_pairs << source_target_pair(source_dir, target_dir)
          self
        end
        
        def git_add_needed?
          true
        end

        private

        SourceTargetDirPair = Struct.new(:absolute_source_dir, :relative_target_dir)

        def add_files_git_repo_manager(git_repo_manager)
          base_target_dir = git_repo_manager.path
          
          @source_target_pairs.each do |source_target_pair|
            absolute_source_dir = source_target_pair.absolute_source_dir
            absolute_target_dir = "#{base_target_dir}/#{source_target_pair.relative_target_dir}"
            FileUtils.mkdir_p(absolute_target_dir)
            FileUtils.cp_r("#{absolute_source_dir}/.", absolute_target_dir)
          end
        end
        
        TARGET_DIR_DEFAULT = '.'
        def source_target_dir_pair(source_dir, target_dir = nil)
          fail Error, "Unexpected that source_dir is nil" if source_dir.nil?
          SourceTargetDirPair.new(source_dir, target_dir || TARGET_DIR_DEFAULT) 
        end
        
      end
    end
  end
end
