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
    class DirectoryParser < ::DTK::DSL::DirectoryParser
      require_relative('directory_parser/git')

      # file_types - a single or array of :DTK::DSL::FileObj objects
      # opts can have keys
      #   :branch - Module::Branch
      #   :file_path - string
      #   :dir_path - string
      # Returns :DTK::DSL::FileObj that matches a file_typeo bject that matches a file_type in file_types
      #   or returns nil if no match found
      def self.matching_file_obj?(file_types, opts = {})
        adapter(file_types, opts).matching_file_obj?(opts)
      end

      private

      def self.adapter(file_types, opts = {})
        unless branch = opts[:branch]
          fail Error, "option :branch is required"
        end
        Git.new(file_types, branch)
      end
    end
  end
end
