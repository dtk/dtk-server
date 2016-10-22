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
module DTK; module CommonDSL
  class Diff
    module ServiceInstance
      require_relative('service_instance/top_dsl_file')
      require_relative('service_instance/nested_module')

      # returns object of type Diff::Result  or raises error
      # TODO: DTK-2665: look at more consistently eithr putting error messages on results
      # or throwing errors
      # also look at doing pinpointed violation chaecking leveraging violation code
      def self.process(service_instance, module_branch, repo_diffs_summary)
        diff_result = Result.new(repo_diffs_summary)
        impacted_files = repo_diffs_summary.impacted_files
        Model.Transaction do
          TopDslFile.process_top_dsl_file?(diff_result, service_instance, module_branch, impacted_files)
          pp [:diff_result, diff_result]
          unless diff_result.any_errors?
            NestedModule.process_nested_modules?(diff_result, service_instance, module_branch, impacted_files)
          end
        end
        diff_result
      end

    end
  end
end; end
