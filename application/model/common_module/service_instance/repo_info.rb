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
  class CommonModule
    class ServiceInstance
      class RepoInfo < ::Hash
        def initialize(base_module_branch)
          replace(base_module: ModuleRepoInfo.new(base_module_branch), nested_modules: [])
        end
        
        def add_nested_module_info!(nested_module_branch)
          self[:nested_modules] << ModuleRepoInfo.new(nested_module_branch)
          self
        end
      end
    end
  end
end
