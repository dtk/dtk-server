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
module DTK; class Target
  class IAASProperties
    class Ec2 < self
      module Type
        Ec2        = IAASProperties::Type::Ec2
        Ec2Classic = :ec2_classic
        Ec2Vpc     = :ec2_vpc
      end

      def initialize(hash_args, provider = nil)
        super(hash_args)
        if provider
          @provider = provider
          #sanitizing what goes in provider_iaas_props, which is used for cloning targets
          @provider_iaas_props = (provider.get_field?(:iaas_properties) || {}).reject { |k, _v| [:key, :secret].include?(k) }
        end
      end

      # returns an array of IAASProperties::Ec2 objects
      def self.check_and_compute_needed_iaas_properties(target_name, ec2_type, provider, property_hash)
        ret = []
        iaas_property_factory = new({ name: target_name }, provider)
        ret << iaas_property_factory.create_target_propeties(ec2_type, property_hash)
        region = property_hash[:region]
        if Ec2TypesNeedingAZTargets.include?(ec2_type)
          # TODO: when have nested targets will nest availability zone targets in the one justa ssociarted with region
          # add iaas_properties for targets created separately for every availability zone
          provider.get_availability_zones(region).each do |az|
            ret << iaas_property_factory.create_target_propeties(ec2_type, property_hash, availability_zone: az)
          end
        end
        ret
      end
      Ec2TypesNeedingAZTargets = [Type::Ec2Classic]

      def create_target_propeties(ec2_type, target_property_hash, params = {})
        iaas_properties = clone_and_check_manditory_params(target_property_hash)
        iaas_properties = { ec2_type: ec2_type }.merge(iaas_properties)
        name = name()
        if az = params[:availability_zone]
          name = availbility_zone_target_name(name, az)
          iaas_properties = { availability_zone: az }.merge(iaas_properties)
        end
        self.class.new(name: name, iaas_properties: iaas_properties)
      end

      def self.equal?(i2)
        i2.type == Type::Ec2 &&
          iaas_properties[:region] == i2.iaas_properties[:region]
      end

      private

      def availbility_zone_target_name(name, availbility_zone)
        "#{name}-#{availbility_zone}"
      end

      def clone_and_check_manditory_params(target_property_hash)
        ret = target_property_hash
        unless target_property_hash[:keypair]
          if keypair = @provider_iaas_props[:keypair]
            ret = ret.merge(keypair: keypair)
          else
            fail ErrorUsage.new('The context and its parent provider are both missing a keypair')
          end
        end

        unless target_property_hash[:security_group] || target_property_hash[:security_group_set]
          if security_group = @provider_iaas_props[:security_group]
            ret = ret.merge(security_group: security_group)
          elsif security_group_set = @provider_iaas_props[:security_group_set]
            ret = ret.merge(security_group_set: security_group_set)
          else
            fail ErrorUsage.new('The context and its parent provider are both missing any security groups')
          end
        end
        # using @provider[:iaas_properties] because has credentials)
        unless props_with_creds = @provider[:iaas_properties]
          Log.error('Unexpected that @provider[:iaas_properties] is nil')
          return ret
        end
        props_with_creds = props_with_creds.merge(target_property_hash)
        self.class.check(Type::Ec2, props_with_creds, properties_to_check: PropertiesToCheck)

        ret
      end
      PropertiesToCheck = [:subnet] #TODO: will add more properties to check

      def self.modify_for_print_form!(iaas_properties)
        if iaas_properties[:security_group_set]
          iaas_properties[:security_group] ||= iaas_properties[:security_group_set].join(',')
        end
        iaas_properties
      end

      def self.sanitize!(iaas_properties)
        iaas_properties.reject! { |k, _v| not SanitizedProperties.include?(k) }
      end
      SanitizedProperties = [:region, :keypair, :security_group, :security_group_set, :subnet, :ec2_type, :availability_zone]

      def self.more_specific_type?(iaas_properties)
        ec2_type = iaas_properties[:ec2_type]
        case ec2_type && ec2_type.to_sym
          when Type::Ec2Vpc then Type::Ec2Vpc
        end
      end
    end
  end
end; end
