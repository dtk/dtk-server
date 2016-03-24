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
module DTK; module CommandAndControlAdapter
  class Ec2
    # For interpreting AWS target service instances
    class TargetService
      r8_nested_require('target_service', 'component')
      
      def self.find_violations(target_service, cmps, project, params = {})
        ret           = []
        any_unset_attributes = params[:any_unset_attributes]
        specific_type = target_service.get_field?(:specific_type)
        
        if specific_type && specific_type.eql?('target')
          project_idh   = project.id_handle()
          target        = target_service.get_target
          provider      = Target::Template.provider_exists?(project_idh, target_service[:display_name])
          
          # TODO: DTK-2948: Aldin these can be multiple provider_cmps, and the other component types
          # We can stub right now assuming that there is one provider and it is aws; when move beyond this
          # restriction then we need to first find the provider objects and for each one find the 
          # objects underneath them that are required; need to decide if raise violation or just warning
          # if one provider has all objects needed will others do not
          # for now keep code orgaized as is, but when we treat multuple IAAS provider types
          # we can have an abstract object with subclasses for each provider type that given teh set of comnponents
          # will form for each porvider and obejcts under it an object that has its substructure
          # As an example for a AWS object would have nested under it a vpc which in turn has
          # security group and subnet objects under it
          missing_cmps   = []
          provider_cmp   = cmps.find{ |cmp| cmp[:component_type].eql?(Component::Type.provider) }
          vpc_cmp        = cmps.find{ |cmp| cmp[:component_type].eql?(Component::Type.vpc) }
          vpc_subnet_cmp = cmps.find{ |cmp| cmp[:component_type].eql?(Component::Type.vpc_subnet) }
          s_group_cmp    = cmps.find{ |cmp| cmp[:component_type].eql?(Component::Type.security_group) }

          # Should put in names of missing components
          missing_cmps << Component::Name.provider unless provider_cmp
          missing_cmps << Component::Name.vpc unless vpc_cmp
          missing_cmps << Component::Name.vpc_subnet unless vpc_subnet_cmp
          missing_cmps << Component::Name.security_group unless s_group_cmp

          unless missing_cmps.empty?
            return [Violation::ProviderOrTargetCmpsMissing.new(missing_cmps)]
          end

          # The methods below should only be called if no unset attributes
          return ret if any_unset_attributes

          if provider
            Target::Template.update_provider_from_converge(provider_cmp, s_group_cmp, project, provider) 
          else
            provider = Target::Template.create_provider_from_converge(provider_cmp, s_group_cmp, project) 
          end

          if target
            Target::Instance.update_target_from_converge(vpc_cmp, vpc_subnet_cmp, s_group_cmp, provider, project, target)
          else
            target = Target::Instance.create_target_from_converge(vpc_cmp, vpc_subnet_cmp, s_group_cmp, provider, project)
          end
        end
        ret
      end

    end
  end
end; end

