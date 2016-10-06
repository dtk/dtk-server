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
      # Using violations to fill in values of target components and validate them
      class ViolationProcessor
        def self.validate_and_fill_in_values(target_service, params = {})
          new(target_service).validate_and_fill_in_values!(params)
        end
        
        def initialize(target_service)
          @reified_target = Target.new(target_service)
        end

        def validate_and_fill_in_values!(params = {})
          ret = []
          any_unset_attributes = params[:any_unset_attributes]
          
          # Get all relevant components
          ndx_components = ComponentType.all.inject({}) do |h, cmp_type|
            h.merge(cmp_type => @reified_target.get_all_components_of_type(cmp_type))
          end
          
#          missing_cmp_types = ComponentType.all.select { |cmp_type| ndx_components[cmp_type].empty? }
#          unless missing_cmp_types.empty?
#            missing_cmp_names = missing_cmp_types.map{ |cmp_type| ComponentType.name(cmp_type) }
#            return [Violation::TargetServiceCmpsMissing.new(missing_cmp_names)]
#          end        
          
          return ret if any_unset_attributes

          # validate_and_fill_in_values each reified_component
          # Need to do this in following order due to using earlier in order components to fill in gaps of later ones
          # Do this first for iam_user and stop theer since error will be invalid credentials

          iam_user_viols = ndx_components[:iam_user].map { |reified_component| reified_component.validate_and_fill_in_values! }.flatten(1)
          ret += iam_user_viols
          return ret unless iam_user_viols.empty?
          ordered_cmp_type = [:vpc]
          ordered_cmp_type.each do |cmp_type|
            ndx_components[cmp_type].each do |reified_component|
              ret += reified_component.validate_and_fill_in_values!
            end
          end
          ret
        end
      end
    end
  end
end

