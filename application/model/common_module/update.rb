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
  class CommonModule
    class Update < self
      require_relative('update/base_service')
      require_relative('update/service_instance')
      # TODO: put in when treat service instance component modules
      # require_relative('update/base_component')

      def self.update_class(common_module_type)
        case common_module_type
        when :base_service then BaseService
        when :base_component then BaseComponent
        when :service_instance then ServiceInstance
        else fail Error, "Illegal common_module_type '#{common_module_type}'"
        end
      end

    end
  end
end
