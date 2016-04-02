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

# TODO: move this under reified/components/target_service/
module DTK
  class CommandAndControlAdapter::Ec2
    module Reified
      r8_nested_require('reified','connected_component_mixin')
      # connected_component_mixin must go first
      r8_nested_require('reified','logical_node')
      r8_nested_require('reified','target')
    end
  end
end

