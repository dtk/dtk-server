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
module DTK; class ModuleDSL; class V4
  class ObjectModelForm
    class ActionDef
      class ActionDefOutputHash < OutputHash
        def has_create_action?
          ::DTK::ActionDef::Constant.matches?(self, :CreateActionName)
        end
        
        def delete_create_action!
          if kv = ::DTK::ActionDef::Constant.matching_key_and_value?(self, :CreateActionName)
            delete(kv.keys.first)
          end
        end

      end
    end
  end
end; end; end
