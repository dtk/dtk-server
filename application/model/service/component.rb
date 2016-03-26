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
  class Service
    class Component
      attr_reader :type

      # Argument dtk_component is of type DTK::Component
      def initialize(dtk_component)
        @dtk_component = dtk_component
        @type = ret_type(dtk_component)
        # @attributes is computed on demand
        @attributes = nil
      end

      private

      def ret_type(dtk_component)
        dtk_component.get_field?(:component_type).gsub('__', '::')
      end
    end
  end
end
