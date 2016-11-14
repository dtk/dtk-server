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
  module CommonDSL::Parse
    class NestedModuleInfo
      class ImpactedFile
        attr_reader :path
        # opts can have keys
        #  :is_dsl_file
        def initialize(parent, path, opts = {})
          @parent     = parent
          @path       = path
          @is_dsl_file = opts[:is_dsl_file] || ret_is_dsl_file?(path)

          #dyanmically set
          @content = nil
        end
        
        def is_dsl_file?
          @is_dsl_file
        end

        def content
          @content ||= RepoManager.get_file_content(@path, @parent.service_module_branch)
        end

        private

        # TODO: DTK-2707 use dtk-dsl library rather than hard coding here
        TOP_COMPONENT_MODULE_DSL_FILE_REGEXP = /dtk\.model\.yaml$/
           [
           /dtk\.model\.yaml$/,
           /dtk\.nested_module\.yaml$/
          ]

        def ret_is_dsl_file?(path)
          if path =~ TOP_COMPONENT_MODULE_DSL_FILE_REGEXP
            true
          elsif  path == top_nested_module_dsl_path
            true
          else
            false
          end
        end

        def top_nested_module_dsl_path
          @parent.top_nested_module_dsl_path
        end
        
      end
    end
  end
end

