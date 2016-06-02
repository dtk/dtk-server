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
  module Module
    class Component < ComponentModule

      private

      # This causes all get_obj(s) class an insatnce methods to return Module::Component objects, rather than ComponentModule ones
      def self.get_objs(model_handle, sp_hash, opts = {})
        if model_handle[:model_name] == :component_module
          super.map { |component_module| Component.copy_as(component_module) }
        else
          super
        end
      end
    end
  end
end
