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
module DTK; class CommandAndControlAdapter::Ec2
  class CreateNode
    class CreateOptions < ::Hash
      # opts can have keys
      #   :primary_nic 
      def initialize(parent, conn, image, opts ={})
        super()
        replace(image_id: image.image_id, flavor_id: parent.flavor_id)

        @conn         = conn
        @reified_node = parent.reified_node
        @node         = parent.node
        @external_ref = parent.external_ref 
        @image        = image
        @primary_nic  = opts[:primary_nic]

        finalize!
      end

      private

      def finalize!
        update_security_group!
        update_tags!
        update_key_name
        update_availability_zone!
        update_vpc_info?
        update_block_device_mapping!
        update_user_data!
        update_client_token?
      end

      def update_security_group!
        merge!(security_group_ids: @reified_node.security_group_ids, groups: @reified_node.security_group_names)
      end

      def update_tags!
        merge!(tags: { 'Name' => ec2_name_tag() })
      end

      def update_key_name
        merge!(key_name: @target.get_keypair() || R8::Config[:ec2][:keypair])
      end

      def update_availability_zone!
        target_availability_zone = (@target[:iaas_properties] || {})[:availability_zone]
        avail_zone = @external_ref[:availability_zone] ||
          (@target[:iaas_properties] || {})[:availability_zone] ||
          R8::Config[:ec2][:availability_zone]
        unless avail_zone.nil? || avail_zone == 'automatic'
          merge!(availability_zone: avail_zone)
        end
      end
      
      def update_vpc_info?
        if @target.is_builtin_target?()
          #TODO: we wil get rid of this special case and just put the info in builtin target
          if R8::Config[:ec2][:vpc_enable]
            subnet_id = @conn.check_for_subnet(R8::Config[:ec2][:vpc][:subnet_id])
            merge!(subnet_id: subnet_id, associate_public_ip: R8::Config[:ec2][:vpc][:associate_public_ip])
            merge!(groups: R8::Config[:ec2][:vpc][:security_group])
            return
          end
        end
        
        unless iaas_properties = @target[:iaas_properties]
          Log.error_pp(['Unexpected that @target does not have :iaas_properties', @target])
          return
        end
        
        update_subnet_id!(iaas_properties) if iaas_properties[:ec2_type] == 'ec2_vpc'
      end

      def update_subnet_id!(iaas_properties)
        # for subnet id; first look whether there is a primary nic component; then look at target default
        unless subnet_id = (subnet_id_on_primary_nic_component? || iaas_properties[:subnet])
          fail ErrorUsage, "There is no subnet id specified"
        end

        @conn.check_for_subnet(subnet_id)
        associate_public_ip = true #TODO: stub value
        merge!(subnet_id: subnet_id, associate_public_ip: associate_public_ip)
      end

      def update_block_device_mapping!
        root_device_override_attrs = { 'Ebs.DeleteOnTermination' => 'true' }
        if root_device_size = @node.attribute.root_device_size()
          root_device_override_attrs.merge!('Ebs.VolumeSize' => root_device_size)
        end
        # only add block_device_mapping if it was fully generated
        if block_device_mapping = @image.block_device_mapping?(root_device_override_attrs)
          merge!(block_device_mapping: block_device_mapping)
        end
      end

      def subnet_id_on_primary_nic_component?
        @primary_nic && @primary_nic.subnet_id
      end

      def update_user_data!
        self[:user_data] ||= CommandAndControl.install_script(@node)
        self
      end

      def update_client_token?
        if client_token = @external_ref[:client_token]
          self[:client_token] ||= client_token
        else
          Log.error_pp(['Unexpected that @external_ref does not have client_token', @node, @external_ref])
        end
        self
      end

      def get_security_group_ids(security_group)
        security_group_ids = []

        if security_group.is_a?(Array)
          security_group.each do |group|
            group_id = check_for_security_group_id(group)
            security_group_ids << group_id if group_id
          end
        else
          group_id = check_for_security_group_id(security_group)
          security_group_ids << group_id if group_id
        end

        security_group_ids
      end

      def check_for_security_group_id(security_group)
        if check_security_group = @conn.check_for_security_group(security_group)
          check_security_group.group_id
        end
      end

      def ec2_name_tag
        # TO-DO: move the tenant name definition to server configuration
        tenant = ::DtkCommon::Aux.running_process_user()
        subs = {
          assembly: ec2_name_tag__get_assembly_name(),
          node: @node.get_field?(:display_name),
          tenant: tenant,
          target: @target[:display_name],
          user: CurrentSession.get_username()
        }
        ret = Ec2NameTag[:tag].dup
        Ec2NameTag[:vars].each do |var|
          val = subs[var] || var.to_s.upcase
          ret.gsub!(Regexp.new("\\$\\{#{var}\\}"), val)
        end
        ret
      end

      Ec2NameTag = {
        vars: [:assembly, :node, :tenant, :target, :user],
        tag: R8::Config[:ec2][:name_tag][:format]
      }

      def ec2_name_tag__get_assembly_name
        if assembly = @node.get_assembly?()
          assembly.get_field?(:display_name)
        else
          node_ref = @node.get_field?(:ref)
          # looking for form base_node_link--ASSEMBLY::NODE-EDLEMENT-NAME
          if node_ref =~ /^base_node_link--([^:]+):/
            Regexp.last_match(1)
          else
            Log.error_pp(['Unexepected that cannot determine assembly name for node', @node])
          end
        end
      end
    end
  end
end; end
