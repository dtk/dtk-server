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
    require_relative('common_dsl/file_type')
    require_relative('common_dsl/diff')
    # diff must be before generate
    require_relative('common_dsl/generate')
    require_relative('common_dsl/parse')
    require_relative('common_dsl/component_module_repo_sync')
    require_relative('common_dsl/service_module_repo_sync')

    # object_logic must go last
    require_relative('common_dsl/object_logic')
  end
end
