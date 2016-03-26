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
  class CommandAndControlAdapter::Ec2::TargetServiceHelper
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
        ndx_matching_cmps = Service::Target.ndx_matching_components?(cmps, Component::Type::All)
        missing_cmps = Component::Type::All.select do |cmp_type|
          ndx_matching_cmps[cmp_type].empty?
        end        
        unless missing_cmps.empty?
          return [Assembly::Instance::Violation::ProviderOrTargetCmpsMissing.new(missing_cmps)]
        end
        
        # The methods below should only be called if no unset attributes
        return ret if any_unset_attributes

        provider = update_or_create_provider(target_service, ndx_matching_cmps, project)
        update_or_create_target(target_service, ndx_matching_cmps, provider, project)
        ret
      end

      private
      
      ######## TODO: will remove create/update provider and target #############
      def self.update_or_create_provider(target_service, ndx_matching_cmps, project)
        provider_attributes  = get_component_attributes(provider_component(ndx_matching_cmps))
        iaas_properties      = provider_iaas_properties(provider_attributes, security_group_component(ndx_matching_cmps))
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

      def self.update_or_create_target(target_service, ndx_matching_cmps, provider, project)
        iaas_properties = target_iaas_attributes(ndx_matching_cmps)

        if target = target_service.target
          target.update({iaas_properties: iaas_properties, parent_id: provider.id()})
        else
          target_type = :ec2_vpc
          target = Target::Instance.create_target(target_type, project.id_handle, provider, iaas_properties)
        end
        target
      end

      ######## end: will remove create/update provider and target #############

      def self.provider_name(provider_attributes)
        name_attribute = provider_attributes.find{ |attribute| attribute[:display_name] == 'name'}
        Target::Template.provider_display_name(name_attribute[:attribute_value])
      end

      ProviderAttributeNames = ['default_key_pair', 'aws_access_key_id', 'aws_secret_access_key']
      def self.provider_iaas_properties(provider_attributes, s_group_cmp)
        keypair, key, secret = get_attribute_values(ProviderAttributeNames, provider_attributes)

        { aws_access_key_id: key, aws_secret_access_key: secret }.each_pair do |name, val|
          # This is an internal logic error, not a user error
          fail Error.new("This function should not be called if '#{name}' is nil") if val.nil?
        end

        s_group_cmp_attributes = get_component_attributes(s_group_cmp)
        security_group = get_attribute_value?('group_name', s_group_cmp_attributes)

        {
          :keypair => keypair,
          :key => key,
          :secret => secret,
          :security_group => security_group
        }
      end

      TargetAttributeNames = ['reqion', 'aws_access_key_id', 'aws_secret_access_key']
      def self.target_iaas_attributes(ndx_matching_cmps)
        vpc_cmp_attributes = get_component_attributes(vpc_component(ndx_matching_cmps))
        region, key, secret = get_attribute_values(TargetAttributeNames, vpc_cmp_attributes)

        { aws_access_key_id: key, aws_secret_access_key: secret, region: region }.each_pair do |name, val|
          # This is an internal logic error, not a user error
          fail Error.new("This function should not be called if '#{name}' is nil") if val.nil?
        end

        vpc_subnet_cmp_attributes = get_component_attributes(vpc_subnet_component(ndx_matching_cmps))
        availability_zone = get_attribute_value?('availability_zone', vpc_subnet_cmp_attributes)
        
        s_group_cmp_attributes = get_component_attributes(security_group_component(ndx_matching_cmps))
        security_group = get_attribute_value?('group_name', s_group_cmp_attributes)

        {
          :region => region,
          :key => key,
          :secret => secret,
          :security_group => security_group,
          :availability_zone => availability_zone
        }
      end

      def self.provider_component(ndx_matching_cmps)
        single_element(Component::Type.provider, ndx_matching_cmps)
      end

      def self.security_group_component(ndx_matching_cmps)
        single_element(Component::Type.security_group, ndx_matching_cmps)
      end

      def self.vpc_component(ndx_matching_cmps)
        single_element(Component::Type.vpc, ndx_matching_cmps)
      end

      def self.vpc_subnet_component(ndx_matching_cmps)
        single_element(Component::Type.vpc_subnet, ndx_matching_cmps)
      end


      def self.single_element(component_type, ndx_matching_cmps)
        matches = ndx_matching_cmps[component_type]
        if matches.size > 1
          Log.error("Current not treating multiple elements. Got multiple elements of type '#{component_type}'")
          matches.first
        else
          matches.first
        end
      end
      
      # returns array with same length as names with values for each name it finds
      def self.get_attribute_values(names, attributes)
        av_pairs = attributes.inject({}) { |h, attr| h.merge(attr[:display_name] => attr[:attribute_value]) }
        names.map { |name| av_pairs[name] }
      end

      def self.get_attribute_value?(name, attributes)
        get_attribute_values([name], attributes).first
      end

      def self.get_component_attributes(component)
        component.get_component_with_attributes_unraveled({})[:attributes]
      end
    end
  end
end

