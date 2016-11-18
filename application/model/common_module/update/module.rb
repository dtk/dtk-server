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
  class CommonModule::Update
    class Module < self
      require_relative('module/service_info')
      # TODOL: add in require_relative('module/component_info')
      
      # opts can have keys
      #   :local_params (required)
      #   :repo_name (required)
      #   :force_pull - Boolean (default false) 
      #   :force_parse - Boolean (default false) 
      def self.update_from_repo(project, commit_sha, opts = {})
        # TODO: DTK-2766: pull in both service and component info. 
        # calss to merge their prt and shoudl change to ModuleServiceInfo and ModuleComponentInfo
        ServiceInfo.update_from_repo(project, commit_sha, opts)
        # ComponentInfo.update_from_repo(project, commit_sha, opts)
      end

      private

      def self.service_info_remote_name
        RepoManager::Constant.service_info_remote_name
      end
      def self.component_info_remote_name
        RepoManager::Constant.component_info_remote_name
      end
    end
  end
end
