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
module DTK; class ModuleDSL; class V3
  OMFBase = ModuleDSL::V2::ObjectModelForm
  class ObjectModelForm < OMFBase
    private

    # opts can have keys
    #   :dependent_modules - if not nil then array of strings that are depenedent modules
    def context(input_hash, opts = {})
      ret = super(input_hash)
      if module_level_includes = input_hash['includes'] || opts[:dependent_modules] 
        ret.merge!(module_level_includes: module_level_includes)
      end
      ret
    end
  end
end; end; end
