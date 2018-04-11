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
    module Generate
      class ContentInput
        require_relative('content_input/diff_mixin')
        require_relative('content_input/diff_class_mixin')
        # diff_mixin and diff_class_mixin need to be before hash and array because it has mixins used by these
        require_relative('content_input/hash')
        require_relative('content_input/array')
        
        def self.generate_for_service_instance(service_instance, module_branch)
          ObjectLogic::ServiceInstance.new(service_instance, module_branch).generate_content_input!
        end

        def self.generate_for_nested_module(service_module_branch,  dsl_file_input_hash, module_ref)
          ObjectLogic::ServiceInstance.new(service_instance, module_branch).generate_content_input!
        end

        def self.generate_base_content_for_service_instance(service_instance, module_branch)
          ObjectLogic::ServiceInstance.new(service_instance, module_branch).generate_simple_content_input!
        end
      end
    end
  end
end
