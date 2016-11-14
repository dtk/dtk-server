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
    class ComponentModuleRepoSync
      class Transform
        require_relative('transform/sync_branch')
        require_relative('transform/service_instance')

        private

        COMPONENT_MODULE_DSL_FILENAME = 'dtk.model.yaml'
        def component_module_dsl_filename
          COMPONENT_MODULE_DSL_FILENAME
        end

        def module_refs_filename
          self.class.module_refs_filename
        end
        def self.module_refs_filename
          @module_refs_filename ||= ModuleRefs.meta_filename_path
        end

      end
    end
  end
end
