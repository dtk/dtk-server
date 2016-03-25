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
  class CommandAndControlAdapter::Ec2::TargetService
    module Violation
      def self.find_violations(target_service, cmps, project, params = {})
        ret = []
        any_unset_attributes = params[:any_unset_attributes]
        
        # TODO: DTK-2948: Aldin these can be multiple provider_cmps, and the other component types
        # We can stub right now assuming that there is one provider and it is aws; when move beyond this
        # restriction then we need to first find the provider objects and for each one find the 
        # objects underneath them that are required; need to decide if raise violation or just warning
        # if one provider has all objects needed will others do not
        # for now keep code orgaized as is, but when we treat multuple IAAS provider types
        # we can have an abstract object with subclasses for each provider type that given teh set of comnponents
        # will form for each provider and obejcts under it an object that has its substructure
        # As an example for a AWS object would have nested under it a vpc which in turn has
        # security group and subnet objects under it
        missing_cmps   = []
        provider_cmp   = cmps.find{ |cmp| cmp[:component_type].eql?(Component::Type.provider) }
        vpc_cmp        = cmps.find{ |cmp| cmp[:component_type].eql?(Component::Type.vpc) }
        vpc_subnet_cmp = cmps.find{ |cmp| cmp[:component_type].eql?(Component::Type.vpc_subnet) }
        s_group_cmp    = cmps.find{ |cmp| cmp[:component_type].eql?(Component::Type.security_group) }
        
        missing_cmps << Component::Name.provider unless provider_cmp
        missing_cmps << Component::Name.vpc unless vpc_cmp
        missing_cmps << Component::Name.vpc_subnet unless vpc_subnet_cmp
        missing_cmps << Component::Name.security_group unless s_group_cmp
        
        unless missing_cmps.empty?
          return [Assembly::Instance::Violation::ProviderOrTargetCmpsMissing.new(missing_cmps)]
        end
        
        # The methods below should only be called if no unset attributes
        return ret if any_unset_attributes

        provider = update_or_create_provider(target_service, provider_cmp, s_group_cmp, project)

        update_or_create_target(target_service, vpc_cmp, vpc_subnet_cmp, s_group_cmp, provider, project)

        ret
      end

      private
      
      ######## TODO: will remove create/update provider and target #############
      def self.update_or_create_provider(target_service, provider_cmp, s_group_cmp, project)
        provider_attributes  = provider_attributes(provider_cmp)
        iaas_properties      = provider_iaas_properties(provider_attributes, s_group_cmp)
        provider_name        = provider_name(provider_attributes)
        project_idh          = project.id_handle
        if provider = Target::Template.provider_exists?(project_idh, target_service.display_name)
          provider.update({iaas_properties: iaas_properties, display_name: provider_name})
        else
          iaas_type  = 'ec2'
          provider = Target::Template.create_provider?(project_idh, iaas_type, provider_name, iaas_properties)
        end
        provider
      end

      def self.update_or_create_target(target_service, vpc_cmp, vpc_subnet_cmp, s_group_cmp, provider, project)
        if target = target_service.target
          Target::Instance.update_target_from_converge(vpc_cmp, vpc_subnet_cmp, s_group_cmp, provider, project, target)
        else
          Target::Instance.create_target_from_converge(vpc_cmp, vpc_subnet_cmp, s_group_cmp, provider, project)
        end
      end

      def self.provider_attributes(provider_cmp)
        provider_cmp.get_component_with_attributes_unraveled({})[:attributes]
      end

      def self.provider_name(provider_attributes)
        name_attribute = provider_attributes.find{ |attribute| attribute[:display_name] == 'name'}
        Target::Template.provider_display_name(name_attribute[:attribute_value])
      end

      def self.provider_iaas_properties(provider_attributes, s_group_cmp)
        keypair = key = secret = nil
        provider_attributes.each do |attribute|
          case attribute[:display_name]
            when 'default_key_pair'
              keypair = attribute[:attribute_value]
            when 'aws_access_key_id'
              key = attribute[:attribute_value]
            when 'aws_secret_access_key'
              secret = attribute[:attribute_value]
          end
        end

        { aws_access_key_id: key, aws_secret_access_key: secret }.each_pair do |name, val|
          # This is an internal logic error, not a user error
          fail Error.new("This function should not be called if '#{name}' is nil") if val.nil?
        end

        security_group = nil
        s_group_cmp_attributes = s_group_cmp.get_component_with_attributes_unraveled({})[:attributes]
        s_group_cmp_attributes.each do |sgcmp|
          if sgcmp[:display_name].eql?('group_name')
            security_group = sgcmp[:value_asserted] || sgcmp[:value_derived]
            break
          end
        end

        {
          :keypair => keypair,
          :key => key,
          :secret => secret,
          :security_group => security_group
        }
      end
      ######## end: will remove create/update provider and target #############
    end
  end
end


