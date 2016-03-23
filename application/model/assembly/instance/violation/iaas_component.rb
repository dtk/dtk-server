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
      PROVIDER_COMP_NAME  = 'aws::iam_user'
      VPC_CMP_NAME        = 'aws::vpc'
      VPC_SUBNET_CMP_NAME = 'aws::vpc_subnet'
      SECURITY_GROUP_CMP  = 'aws::security_group'

      def self.find_violations(target_service, cmps, project)
        ret           = []
        specific_type = target_service.get_field?(:specific_type)

        if specific_type && specific_type.eql?('target')
          project_idh   = project.id_handle()
          target        = target_service.get_target
          provider      = Target::Template.provider_exists?(project_idh, target_service[:display_name])

          # TODO: DTK-2948: Aldin these can be multiple provider_cmps, and the other component types
          # We can start with treating just single ones
          missing_cmps   = []
          provider_cmp   = cmps.find{ |cmp| cmp[:display_name].eql?(PROVIDER_COMP_NAME.gsub('::', '__')) }
          vpc_cmp        = cmps.find{ |cmp| cmp[:display_name].eql?(VPC_CMP_NAME.gsub('::', '__')) }
          vpc_subnet_cmp = cmps.find{ |cmp| cmp[:display_name].eql?(VPC_SUBNET_CMP_NAME.gsub('::', '__')) }
          s_group_cmp    = cmps.find{ |cmp| cmp[:display_name].eql?(SECURITY_GROUP_CMP.gsub('::', '__')) }


          # Should put in names of missing components
          missing_cmps << PROVIDER_COMP_NAME unless provider_cmp
          missing_cmps << VPC_CMP_NAME unless vpc_cmp
          missing_cmps << VPC_SUBNET_CMP_NAME unless vpc_subnet_cmp

          unless missing_cmps.empty?
            return [Violation::ProviderOrTargetCmpsMissing.new(missing_cmps)]
          end

          provider = Target::Template.create_provider_from_converge(provider_cmp, s_group_cmp, project, target_service) unless provider
          if target
            Target::Instance.update_target_from_converge(vpc_cmp, vpc_subnet_cmp, s_group_cmp, provider, project, target)
          else
            target = Target::Instance.create_target_from_converge(vpc_cmp, vpc_subnet_cmp, s_group_cmp, provider, project, target_service)
          end
        end

        # provider = Target::Template.create_provider_from_converge(provider_cmp, s_group_cmp, project)
        # target   = Target::Instance.create_target_from_converge(vpc_cmp, vpc_subnet_cmp, s_group_cmp, provider, project, target_service)
        ret
      end
    end

    class Violation
      class ProviderOrTargetCmpsMissing < self
        def initialize(component_types)
          @component_types = component_types
        end

        def type
          :provider_or_target_cmps_missing
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
