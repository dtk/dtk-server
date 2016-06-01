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
# TODO: need to cleanup breaking into  base_module, component_module, service_module and the DSL related classes
# There is overlap between soem service module and otehr moduel code
# Right now seems intuitive model is that we have
# two types of modules: service module and the rest, the prime being the component module, and that for the rest there is much similarity
# for the rest the classes used are
module DTK
  # order is important
  r8_nested_require('module', 'mixins')
  r8_nested_require('module', 'dsl_parser')
  r8_nested_require('module', 'external_dependencies')
  r8_nested_require('module', 'module_dsl_info') #TODO: this will get deprecated when all move over to update_module_output
  r8_nested_require('module', 'update_module_output')
  r8_nested_require('module', 'base_module')
  r8_nested_require('module', 'component_module')
  r8_nested_require('module', 'service')
  r8_nested_require('module', 'test')
  r8_nested_require('module', 'node')
  r8_nested_require('module', 'branch')
  r8_nested_require('module', 'version')
  r8_nested_require('module', 'assembly_module')

  module Module
    def self.service_module_from_id?(model_handle, module_id)
      ServiceModule.find(model_handle, module_id)
    end
  end
end
