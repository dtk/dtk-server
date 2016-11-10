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
  class RepoManager
    # For backing ut of changes to repos on error
    module Transaction 
      def self.reset_on_error(module_branch, &body)
        sha_before_change = module_branch.current_sha
        begin
          yield
        rescue => e
          # within yield module_branch sha can be changed
          if sha_before_change != module_branch.current_sha
            repo = module_branch.get_repo
            repo.hard_reset_branch_to_sha(module_branch, sha_before_change) 
          end
          raise e
        end
      end
      
    end
  end
end

