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
      def self.find_violations(assembly_instance, components, project, params = {})
        if target_service = Service::Target.create_from_assembly_instance?(assembly_instance, components: components)
          CommandAndControl.find_violations_in_target_service(target_service, project, params) 
        else
          service = Service.new(assembly_instance, components: components)
          CommandAndControl.find_violations_in_node_components(service, project, params) 
        end
      end
    end

    class Violation
      class TargetServiceCmpsMissing < self
        def initialize(component_types)
          @component_types = component_types
        end
        
        def type
          :target_service_cmps_missing
        end
        
        def description
          cmp_or_cmps = (@component_types.size == 1) ? 'Component' : 'Components'
          is_are = (@component_types.size == 1) ? 'is' : 'are'
          
          "#{cmp_or_cmps} of type (#{@component_types.join(', ')}) #{is_are} missing and #{is_are} required for a target service instance"
        end
      end
    end
  end
end
