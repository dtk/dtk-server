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
  module CommonDSL
    # Methods to sync to and from the service instance repo to the component module repos using git subtree operations
    class NestedModuleRepo
      # TODO: DTK-3366: remove these"
      # require_relative('nested_module_repo/transform')
      # require_relative('nested_module_repo/common')

      def initialize(aug_nested_module_branch)
        @aug_nested_module_branch = aug_nested_module_branch
      end
      private :initialize

      def self.update_repo_for_stage(aug_nested_module_branch)
        new(aug_nested_module_branch).update_repo_for_stage
      end
      def update_repo_for_stage
        source_path      = FileType::CommonModule::DSLFile::Top.canonical_path
        destination_path = FileType::ServiceInstance::NestedModule::DSLFile::Top.canonical_path
        RepoManager.move_file(source_path, destination_path, self.aug_nested_module_branch)
        RepoManager.add_all_files_and_commit({}, self.aug_nested_module_branch)
        RepoManager.push_changes(self.aug_nested_module_branch)
        self.aug_nested_module_branch
      end      

      protected

      attr_reader :aug_nested_module_branch

      def nested_module_top_dsl_path
        @nested_module_top_dsl_path ||= ret_nested_module_top_dsl_path
      end

    end
  end
end

