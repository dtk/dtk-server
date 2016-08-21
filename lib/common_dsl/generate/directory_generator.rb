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

      # file_type - class of type FileType
      # opts can have keys
      #   :branch - Module::Branch (required)
      #   :commit_msg
      #   :donot_push_changes - Boolean (default: false)
      # Adds or modifies file; returns true if new file or any change
      def self.add_file?(file_type, file_content, opts = {})
        adapter(file_type, opts).add_file?(file_content, opts)
      end

      private

      def self.adapter(file_type, opts = {})
        unless branch = opts[:branch]
          fail Error, "option :branch is required"
        end
        Git.new(file_type, branch)
      end
    end
  end
end
