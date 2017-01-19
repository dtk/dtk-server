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
  class Assembly::Instance
    module ComponentTemplateMixin
      def find_matching_aug_component_template?(component_type, component_module_refs)
        Component::Template::Augmented.find_matching_component_template(self, component_type, component_module_refs, donot_raise_error: true)
      end

      # opts can have keys:
      #   :donot_raise_error
      #   :dependent_modules
      def find_matching_aug_component_template(component_type, component_module_refs, opts = {})
        Component::Template::Augmented.find_matching_component_template(self, component_type, component_module_refs, opts)
      end

    end
  end
end
