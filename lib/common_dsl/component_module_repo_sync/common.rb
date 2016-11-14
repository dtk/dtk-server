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
      module Common
        NestedModuleFileType = FileType::ServiceInstance::NestedModule

        def self.nested_module_dir(nested_module_name)
          NestedModuleFileType.new(module_name: nested_module_name).base_dir
        end

        def self.nested_module_top_dsl_file_type
          NestedModuleFileType::DSLFile::Top
        end

        def self.nested_module_top_dsl_path(nested_module_name)
          nested_module_top_dsl_file_type.new(module_name: nested_module_name).canonical_path
        end

      end
    end
  end
end
