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
##### temp until convert to DTK
module XYZ
end
DTK = XYZ

module DTK
  module BaseDir
    system_root_path = File.expand_path('../../', File.dirname(__FILE__))
    Lib = "#{system_root_path}/lib"
    App = "#{system_root_path}/application"
    Utils = "#{system_root_path}/utils/internal"

    require File.expand_path("#{App}/require_first", File.dirname(__FILE__))
    dtk_require_common_library()
    dtk_nested_require(Lib, 'configuration')
    dtk_nested_require(Utils, 'aux')
  end
end

   