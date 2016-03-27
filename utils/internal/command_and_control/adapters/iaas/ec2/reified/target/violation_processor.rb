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
  module CommandAndControlAdapter::Ec2::Reified
    class Target
      # TODO: DTK-2489 bridge of using violations to trigger converge of components until have a component implementation
      # that can handle Rest calls 
      class ViolationProcessor
        def self.find_violations(target_service, project, params = {})
          new(target_service).find_violations(project, params)
        end
        
        def initialize(target_service)
          @reified_target = Target.new(target_service)
        end

        def find_violations(project, params = {})
          ret = []
          any_unset_attributes = params[:any_unset_attributes]
          
          # Get all relevant components
          ndx_components = Component::Type::All.inject({}) do |h, cmp_type|
            h.merge(cmp_type => @reified_target.get_all(cmp_type))
          end
          
          missing_cmp_types = Component::Type::All.select { |cmp_type| ndx_components[cmp_type].empty? }
          unless missing_cmp_types.empty?
            missing_cmp_names = missing_cmp_types.map{ |cmp_type| Component::Type.name(cmp_type) }
            return [Violation::TargetServiceCmpsMissing.new(missing_cmp_names)]
          end        
          
          return ret if any_unset_attributes

          ndx_components.each_value do |reified_components|
            reified_components.each do |reified_component|
              ret += reified_component.validate_an_converge!
            end
          end
          ret
        end
      end
    end
  end
end

