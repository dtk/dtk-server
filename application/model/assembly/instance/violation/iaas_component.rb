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
    module IaasComponent
      # TODO: DTK-2948; need to iterate over all
      IAAS_TYPES = [:ec2]
      def self.find_violations(target_service, cmps, project, params = {})
        IAAS_TYPES.inject([]) do  |a, iaas_type|
          a + CommandAndControl.find_violations_in_target_service(iaas_type, target_service, cmps, project, params) 
        end
      end
    end
  end
end
