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
  module V1
    class ModuleController < V1::Base
      require_relative('module/get_mixin')
      require_relative('module/post_mixin')
      include GetMixin
      include PostMixin

      helper_v1 :module_helper
      helper_v1 :module_ref_helper
      helper_v1 :service_helper
      helper :module_helper
      helper :assembly_helper
    end
  end
end