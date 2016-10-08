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
    class DirectoryGenerator < ::DTK::DSL::DirectoryGenerator
      require_relative('directory_generator/git')

      # TODO: change signature to be closer to add_files
      # Adds or modifies file; returns true if new file or any change
      # file_type - class of type FileType
      # opts can have keys
      #   :branch - Module::Branch (required)
      #   :commit_msg
      #   :donot_push_changes - Boolean (default: false)
      def self.add_file?(file_type, file_content, opts = {})
        unless module_branch = opts[:branch]
          fail Error, "option :branch is required"
        end
        adapter(module_branch).add_file?(file_type.canonical_path, file_content, opts)
      end

      # Adds or modifies files in file_type__content_array
      # file_type__content_array - array where each element is a hash with keys :file_type and :content
      # opts can have keys
      #   :commit_msg
      #   :donot_push_changes - Boolean (default: false)
      #   :no_commit - Boolean (default: false)
      def self.add_files(module_branch, file_type__content_array, opts = {})
        file_path__content_array = file_type__content_array.map do |r| 
          { path: r[:file_type].canonical_path, content: r[:content] }
        end
        adapter(module_branch).add_files(file_path__content_array, opts)
      end

      def self.add_remote_files(module_branch, add_remote_files_info)
        adapter(module_branch).add_remote_files(add_remote_files_info)
      end

      private

      def self.adapter(module_branch)
        Git.new(module_branch)
      end
    end
  end
end
