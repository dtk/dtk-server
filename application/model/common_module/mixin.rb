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
  class CommonModule
    module Mixin
    end
  end
end
