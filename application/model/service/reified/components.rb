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
  module Service::Reified
    # Reified::Components holds a set of relataed refined components that relate to each other
    class Components
      def initialize
        # The elements in this hash get set on demand
        # They correspond to all the component types
        @cached_components = {}
      end

      def use_and_set_cache(component_type, &body)
        @cached_components[component_type] ||= yield
      end
    end
  end
end
