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

  # TODO DTK-2587: wil be incrementally moving or depracting these to Module::* classes and modules
  require_relative('module/module_utils')
  require_relative('module/module_common_mixin')
  require_relative('module/module_mixin')
  require_relative('module/module_class_mixin')
  require_relative('module/module_repo_info')

  require_relative('module/dsl_parser')
  require_relative('module/external_dependencies')
  require_relative('module/module_dsl_info') #TODO: this will get deprecated when all move over to update_module_output
  require_relative('module/update_module_output')
  require_relative('module/base_module')
  require_relative('module/component_module')# TODO DTK-2587: cleaning up and moving fns from  component_module to component (Module::Component)
  require_relative('module/service_module') # TODO DTK-2587: cleaning up and moving fns from service_module to service (Module::Service)
  require_relative('module/test')
  require_relative('module/node')
  require_relative('module/branch')
  require_relative('module/version')
  require_relative('module/assembly_module')

  module Module
    require_relative('module/service')
    require_relative('module/component')
  end
end
