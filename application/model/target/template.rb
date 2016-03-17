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
  # This is a provider
  class Target
    class Template < self
      subclass_model :target_template, :target, print_form: 'provider'

      def self.list(target_mh)
        sp_hash = {
          cols: common_columns(),
          filter: object_type_filter()
        }
        get_these_objs(target_mh, sp_hash)
      end

      # if iaas_type is nil means create a generic provider
      def self.create_provider?(project_idh, iaas_type, provider_name, iaas_properties_hash, params_hash = {}, opts = {})
        if existing_provider = provider_exists?(project_idh, provider_name)
          if opts[:raise_error_if_exists]
            fail ErrorUsage.new("Provider (#{provider_name}) exists already")
          else
            return existing_provider
          end
        end

        target_mh = project_idh.createMH(:target)
        display_name = provider_display_name(provider_name)
        ref = display_name.downcase.gsub(/ /, '-')
        create_row = {
          project_id: project_idh.get_id(),
          type: 'template',
          ref: ref,
          display_name: display_name,
          description: params_hash[:description],
        }
        if iaas_type
          iaas_properties = IAASProperties.check(iaas_type, iaas_properties_hash)
          create_row.merge!(iaas_type: iaas_type.to_s, iaas_properties: iaas_properties)
        else
          create_row.merge!(iaas_type: IAASProperties::Type::Generic.to_s)
        end
        create_opts = { convert: true, ret_obj: { model_name: :target_template } }
        create_from_row(target_mh, create_row, create_opts)
      end

      def self.create_provider_from_converge(provider_cmp, s_group_cmp, project)
        provider_attributes    = provider_cmp.get_component_with_attributes_unraveled({})[:attributes]
        s_group_cmp_attributes = s_group_cmp.get_component_with_attributes_unraveled({})[:attributes]

        keypair        = ''
        key            = ''
        secret         = ''
        security_group = ''

        provider_attributes.each do |attribute|
          if attribute[:display_name].eql?('default_key_pair')
            keypair = attribute[:value_asserted] || attribute[:value_derived]
          elsif attribute[:display_name].eql?('aws_access_key_id')
            key = attribute[:value_asserted] || attribute[:value_derived]
          elsif attribute[:display_name].eql?('aws_secret_access_key')
            secret = attribute[:value_asserted] || attribute[:value_derived]
          end
        end

        s_group_cmp_attributes.each do |sgcmp|
          if sgcmp[:display_name].eql?('group_name')
            security_group = sgcmp[:value_asserted] || sgcmp[:value_derived]
            break
          end
        end

        project_idh = project.id_handle()
        iaas_type   = 'ec2'
        provider_name = 'target_test'

        iaas_properties = {
          :keypair => keypair,
          :key => key,
          :secret => secret,
          :security_group => security_group
        }

        Target::Template.create_provider?(project_idh, iaas_type, provider_name, iaas_properties)
      end

      class DeleteResponse < Hash
        def add_target_response(hash)
          hash.each_pair do |msg_type, msg_array|
            pntr = (self[msg_type] ||= [])
            msg_array.each { |msg| pntr << msg }
          end
          self
        end
      end
      def self.delete_and_destroy(provider, opts = {})
        response = DeleteResponse.new()
        unless opts[:force]
          assembly_instances = provider.get_assembly_instances(omit_empty_workspace: true)
          unless assembly_instances.empty?
            assembly_names = assembly_instances.map { |a| a[:display_name] }.join(',')
            provider_name = provider.get_field?(:display_name)
            fail ErrorUsage.new("Cannot delete provider '#{provider_name}' because service instance(s) (#{assembly_names}) are using one of its targets")
          end
        end

        target_instances = provider.get_target_instances(cols: [:display_name, :is_default_target])
        Transaction do
          target_instances.each do |target_instance|
            target_delete_response = Instance.delete_and_destroy(target_instance)
            response.add_target_response(target_delete_response)
          end
          delete_instance(provider.id_handle())
        end
        response
      end

      def create_bootstrap_targets?(project_idh, region_or_regions = nil)
        # for succinctness
        r = region_or_regions
        regions =
          if r.is_a?(Array) then r
          elsif r.is_a?(String) then [r]
          else R8::Config[:ec2][:regions]
          end

        common_iaas_properties = get_field?(:iaas_properties)
        # DTK-1735 DO NOT copy aws key and secret from provider to target
        common_iaas_properties.delete_if { |k, _v| [:key, :secret].include?(k) }

        iaas_properties_list = regions.map do |region|
          name = default_target_name(:ec2, region: region)
          properties = common_iaas_properties.merge(region: region)
          IAASProperties.new(name: name, iaas_properties: properties)
        end
        Instance.create_targets?(project_idh, self, iaas_properties_list)
      end

      def get_availability_zones(region)
        CommandAndControl.get_and_process_availability_zones(get_field?(:iaas_type), get_field?(:iaas_properties).merge(region: region), region)
      end

      def get_assembly_instances(opts = {})
        ret = []
        target_instances = id_handle.create_object().get_target_instances()
        unless target_instances.empty?
          ret = Assembly::Instance.get(model_handle(:assembly_instance), target_idhs: target_instances.map(&:id_handle))
          if opts[:omit_empty_workspace]
            ret.reject! do |assembly|
              if Workspace.is_workspace?(assembly)
                assembly.get_nodes().empty?
              end
            end
          end
        end
        ret
      end

      def get_target_instances(opts = {})
        sp_hash = {
          cols: add_default_cols?(opts[:cols]),
          filter: [:eq, :parent_id, id()]
        }
        Target::Instance.get_objs(model_handle(:target_instance), sp_hash)
      end

      def default_target_name(iaas_type = nil, hash_params = {})
        if iaas_type.nil?
          base_name()
        elsif iaas_type == :ec2
          if Aux.has_just_these_keys?(hash_params, [:region])
            "#{base_name()}-#{hash_params[:region]}"
          else
            fail Error.new("Not implemented when hash_parsm keys are: #{hash_params.keys.join(',')}")
          end
        else
          fail Error.new("type '#{iaas_type}' not supported")
        end
      end

      private

      def base_name
        # get_field?(:display_name).gsub(Regexp.new("#{DisplayNameSufix}$"),'')
        get_field?(:display_name)
      end

      def self.object_type_filter
        [:eq, :type, 'template']
      end

      def self.provider_display_name(provider_name)
        # "#{provider_name}#{DisplayNameSufix}"
        provider_name
      end
      # removed '-template' from provider display_name (ticket DTK-1480)
      # DisplayNameSufix = '-template'

      def self.provider_exists?(project_idh, provider_name)
        sp_hash = {
          cols: [:id],
          filter: [:and, [:eq, :display_name, provider_display_name(provider_name)],
                   [:eq, :project_id, project_idh.get_id()]]
        }
        get_obj(project_idh.createMH(:target_template), sp_hash)
      end
    end
  end
end
