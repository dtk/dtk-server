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
  class Target
    class Instance < self
      r8_nested_require('instance', 'default_target')

      subclass_model :target_instance, :target, print_form: 'target'

      def info
        target =  get_obj(cols: [:display_name, :iaas_type, :iaas_properties, :is_default_target, :provider])
        IAASProperties.sanitize_and_modify_for_print_form!(target[:iaas_type], target[:iaas_properties])
        if provider_name = (target[:provider] || {})[:display_name]
          target[:provider_name] = provider_name
        end
        OrderedInfoKeys.inject({}) do |h, k|
          val = target[k]
          val.nil? ? h : h.merge(k => val)
        end
      end
      OrderedInfoKeys = [:display_name, :id, :provider_name, :iaas_properties, :is_default_target]

      def iaas_properties
        IAASProperties.new(target_instance: self)
      end

      def get_target_running_nodes
        Node::TargetRef.get_target_running_nodes(self)
      end

      # TODO: DTK-2489; Aldin rewrite this and create_target_from_converge using same form that used for
      #  Template.create_provider_from_converge
      def self.update_target_from_converge(vpc_cmp, vpc_subnet_cmp, s_group_cmp, provider, project, target)
        region = key = secret = nil
        vpc_cmp_attributes = vpc_cmp.get_component_with_attributes_unraveled({})[:attributes]
        vpc_cmp_attributes.each do |attribute|
          case attribute[:display_name]
            when 'reqion'
              region = attribute[:attribute_value]
            when 'aws_access_key_id'
              key = attribute[:attribute_value]
            when 'aws_secret_access_key'
              secret = attribute[:attribute_value]
          end
        end

        { aws_access_key_id: key, aws_secret_access_key: secret, region: region }.each_pair do |name, val|
          # This is an internal logic error, not a user error
          fail Error.new("This function should not be called if '#{name}' is nil") if val.nil?
        end

        availability_zone         = nil
        vpc_subnet_cmp_attributes = vpc_subnet_cmp.get_component_with_attributes_unraveled({})[:attributes]
        vpc_subnet_cmp_attributes.each do |attribute|
          if attribute[:display_name].eql?('availability_zone')
            availability_zone = attribute[:value_asserted] || attribute[:value_derived]
          end
        end

        security_group         = nil
        s_group_cmp_attributes = s_group_cmp.get_component_with_attributes_unraveled({})[:attributes]
        s_group_cmp_attributes.each do |sgcmp|
          if sgcmp[:display_name].eql?('group_name')
            security_group = sgcmp[:value_asserted] || sgcmp[:value_derived] || security_group
            break
          end
        end

        iaas_properties = {
          :region => region,
          :key => key,
          :secret => secret,
          :security_group => security_group,
          :availability_zone => availability_zone
        }

        target.update({iaas_properties: iaas_properties, parent_id: provider.id()})
      end

      # These properties are inherited ones for target instance: default provider -> target's provider -> target instance (most specific)
      InheritedProperties = [:iaas_type, :iaas_properties, :type, :description]

      def self.create_target(target_type, project_idh, provider, property_hash, opts = {})
        target_name = opts[:target_name]
        iaas_properties_array = []

        if target_type.nil? # means generic target
          target_name ||= provider.default_target_name
          iaas_properties_array = [IAASProperties.create_generic(target_name)]
        elsif [:ec2_classic, :ec2_vpc].include?(target_type)
          unless region = property_hash[:region]
            fail ErrorUsage.new("Region is required for target created in '#{provider.get_field?(:iaas_type)}' provider type!")
          end
          target_name ||= provider.default_target_name(:ec2, region: region)
          # raises errors if problems with any params
          iaas_properties_array = IAASProperties::Ec2.check_and_compute_needed_iaas_properties(target_name, target_type, provider, property_hash)
        else
          fail ErrorUsage.new("Target type '#{target_type}' is not supported")
        end

        # proactively getting needed columns on provider
        provider.update_obj!(*InheritedProperties)

        create_targets?(project_idh, provider, iaas_properties_array, raise_error_if_exists: true).first
      end

      def self.create_target_from_converge(vpc_cmp, vpc_subnet_cmp, s_group_cmp, provider, project, service_instance)
        region = key = secret = nil
        vpc_cmp_attributes = vpc_cmp.get_component_with_attributes_unraveled({})[:attributes]
        vpc_cmp_attributes.each do |attribute|
          case attribute[:display_name]
            when 'region'
              region = attribute[:attribute_value]
            when 'aws_access_key_id'
              key = attribute[:attribute_value]
            when 'aws_secret_access_key'
              secret = attribute[:attribute_value]
          end
        end

        { aws_access_key_id: key, aws_secret_access_key: secret, region: region }.each_pair do |name, val|
          # This is an internal logic error, not a user error
          fail Error.new("This function should not be called if '#{name}' is nil") if val.nil?
        end

        availability_zone     = nil
        subnet_cmp_attributes = vpc_subnet_cmp.get_component_with_attributes_unraveled({})[:attributes]
        subnet_cmp_attributes.each do |attribute|
          if attribute[:display_name].eql?('availability_zone')
            availability_zone = attribute[:value_asserted] || attribute[:value_derived]
          end
        end

        security_group       = nil
        group_cmp_attributes = s_group_cmp.get_component_with_attributes_unraveled({})[:attributes]
        group_cmp_attributes.each do |sgcmp|
          if sgcmp[:display_name].eql?('group_name')
            security_group = sgcmp[:value_asserted] || sgcmp[:value_derived]
            break
          end
        end

        target_type     = :ec2_vpc
        project_idh     = project.id_handle()
        iaas_properties = {
          :region => region,
          :key => key,
          :secret => secret,
          :security_group => security_group,
          :availability_zone => availability_zone
        }

        create_target(target_type, project_idh, provider, iaas_properties)
      end

      def self.create_targets?(project_idh, provider, iaas_properties_array, opts = {})
        ret = []
        target_mh = project_idh.createMH(:target)
        provider.update_obj!(*InheritedProperties)
        provider_id = provider.id
        create_rows = iaas_properties_array.map do |iaas_properties|
          display_name = iaas_properties.name
          ref = display_name.downcase.gsub(/ /, '-')
          specific_params = {
            parent_id: provider_id,
            ref: ref,
            display_name: display_name,
            type: 'instance'
          }

          el = provider.hash_subset(:iaas_type, :type, :description).merge(specific_params)

          # need deep merge for iaas_properties
          el.merge(iaas_properties: iaas_properties.properties)
        end

        # check if there are any matching target instances that are created already
        disjunct_array = create_rows.map do |r|
          [:and, [:eq, :parent_id, r[:parent_id]],
           [:eq, :display_name, r[:display_name]]]
        end
        sp_hash = {
          cols: [:id, :display_name, :parent_id],
          filter: [:or] + disjunct_array
        }
        existing_targets = get_these_objs(target_mh, sp_hash)
        unless existing_targets.empty?
          if opts[:raise_error_if_exists]
            existing_names = existing_targets.map { |et| et[:display_name] }.join(',')
            obj_type = pp_object_type(existing_targets.size)
            fail ErrorUsage.new("The #{obj_type} (#{existing_names}) exist(s) already")
          else
            create_rows.reject! do |r|
              parent_id = r[:parent_id]
              name = r[:display_name]
              existing_targets.find { |et| et[:parent_id] == parent_id && et[:display_name] == name }
            end
          end
        end

        return ret if create_rows.empty?
        create_opts = { convert: true, ret_obj: { model_name: :target_instance } }
        create_from_rows(target_mh, create_rows, create_opts)
      end

      def self.create_target_mock_for_service_instance(target_name, project_idh)
        target_mh = project_idh.createMH(:target)
        ref = target_name.downcase.gsub(/ /, '-')
        create_rows = {
          ref: ref,
          display_name: target_name,
          type: 'instance',
          iaas_type: 'ec2',
          iaas_properties: {},
          project_id: project_idh.get_id()
        }
        create_opts = { convert: true, ret_obj: { model_name: :target_instance } }
        create_from_rows(target_mh, [create_rows], create_opts)
      end

      def self.validate_if_target_converged(target)
        return unless target
        fail ErrorUsage.new("You are trying to stage service instance in target '#{target.get_field?(:display_name)}' which is not converged. Please go to target service instance, converge it and try 'stage' again.") unless target.get_field?(:parent_id)
      end

      class DeleteResponseObject
        def initialize(target)
          @target_name = target.get_field?(:display_name)
          @info        = {}
        end

        def add_info_changed_default_target!(new_default_target)
          @info[:changed_default_target] = new_default_target
        end

        def add_info_changed_workspace_target!(new_default_target)
          @info[:changed_workspace_target] = new_default_target
        end

        def hash_form
          ret = {}
          return ret if @info.empty?()
          default_target = @info[:changed_default_target]
          workspace_target = @info[:changed_workspace_target]
          if default_target && workspace_target && default_target.id == workspace_target.id
            add_changed_target!(ret, default_target, :default_and_workspace)
          else
            add_changed_target!(ret, default_target, :default) if default_target
            add_changed_target!(ret, workspace_target, :workspace) if workspace_target
          end
          ret
        end

        private

         def  add_changed_target!(ret, new_target, role)
           new_target_name = new_target.get_field?(:display_name)
           this_setting = (role == :default_and_target ? 'these target settings' : 'this target setting')
           role_str = role.to_s.gsub(/_/, ' ')
           msg = "Deleted '#{@target_name}' that was #{role_str} target; changed #{this_setting} to '#{new_target_name}'"
           (ret[:info] ||= []) << msg
           ret
         end
      end

      # returns hash that has response info
      def self.delete_and_destroy(target)
        response_obj = DeleteResponseObject.new(target)
        if target.is_builtin_target?()
          fail ErrorUsage.new('Cannot delete the builtin target')
        end

        target_mh              = target.model_handle()
        builtin_target         = get_builtin_target(target_mh)
        current_default_target = DefaultTarget.get(target_mh)

        Transaction do
          # change default target if pointing to this target
          if current_default_target && current_default_target.id == target.id
            response_obj.add_info_changed_default_target!(builtin_target)
            DefaultTarget.set(builtin_target, current_default_target: current_default_target, update_workspace_target: false)
          end

          assemblies = Assembly::Instance.get(target.model_handle(:assembly_instance), target_idh: target.id_handle())
          assemblies.each do |assembly|
            if workspace = Workspace.workspace?(assembly)
              # modify workspace target if it points to the one being deleted
              if current_workspace_target = workspace.get_target()
                if current_workspace_target.id == target.id
                  response_obj.add_info_changed_workspace_target!(builtin_target)
                  workspace.set_target(builtin_target, mode: :from_delete_target)
                end
              end

              workspace.purge(destroy_nodes: true)
            else
              Assembly::Instance.delete(assembly.id_handle, destroy_nodes: true)
            end
          end
          delete_instance(target.id_handle())
        end
        response_obj.hash_form()
      end

      def self.set_default_target(target, opts = {})
        current_default_target = DefaultTarget.set(target, opts)
        ResponseInfo.info('Default target changed from ?current_default_target to ?new_default_target',
                          current_default_target: current_default_target,
                          new_default_target: target)
      end

      def self.get_default_target(target_mh, cols = [])
        DefaultTarget.get(target_mh, cols)
      end

      def self.set_properties(target, iaas_properties)
        target.update_obj!(:iaas_properties)
        current_properties = target[:iaas_properties]

        # convert string keys to symbols ({'keypair' => 'default'} to {:keypair => 'default'})
        iaas_properties = iaas_properties.inject({}) { |memo, (k, v)| memo[k.to_sym] = v; memo }

        # avoid having security_group and security_group_set in one iaas_properties
        if iaas_properties[:security_group_set] || iaas_properties[:security_group]
          current_properties.delete(iaas_properties[:security_group] ? :security_group_set : :security_group)
        end

        hash_assignments = { iaas_properties: current_properties.merge(iaas_properties) }
        Model.update_from_hash_assignments(target.id_handle(), hash_assignments)
      end

      def self.list(target_mh, opts = {})
        filter = [:neq, :type, 'template']
        if opts[:filter]
          filter = [:and, filter, opts[:filter]]
        end
        sp_hash = {
          cols: [:id, :display_name, :iaas_type, :type, :parent_id, :iaas_properties, :provider, :is_default_target],
          filter: filter
        }
        unsorted_rows = get_these_objs(target_mh, sp_hash)
        unsorted_rows.each do |t|
          if t.is_builtin_target?()
            set_builtin_provider_display_fields!(t)
          end
          IAASProperties.sanitize_and_modify_for_print_form!(t[:iaas_type], t[:iaas_properties])
          if provider = t[:provider]
            IAASProperties.sanitize_and_modify_for_print_form!(provider[:iaas_type], provider[:iaas_properties])
            # modifies iaas_type to make more specfic
            if specific_iaas_type = IAASProperties.more_specific_type?(t[:iaas_type], t[:iaas_properties])
              provider[:iaas_type] = specific_iaas_type
            end
          end
          t[:display_name] = "#{DefaultTargetMark}#{t[:display_name]}" if t[:is_default_target]
        end
        # sort by 1-whether default, 2-iaas_type, 3-display_name
        unsorted_rows.sort do |a, b|
          [a[:is_default_target] ? 0 : 1, a[:iaas_type] || 'generic', a[:display_name]] <=>
          [b[:is_default_target] ? 0 : 1, b[:iaas_type] || 'generic', b[:display_name]]
        end
      end

      DefaultTargetMark = '*'

      def is_builtin_target?
        get_field?(:parent_id).nil?
      end

      def self.import_nodes(target, inventory_data)
        Node::TargetRef.create_nodes_from_inventory_data(target, inventory_data)
      end

      private

      def self.get_builtin_target(target_mh)
        sp_hash = {
          cols: [:id, :group_id, :display_name],
          filter: [:and, [:eq, :parent_id, nil], [:eq, :type, 'staging']]
        }
        rows = get_objs(target_mh, sp_hash)
        unless rows.size == 1
          Log.error("Unexpected that get_builtin_target returned '#{rows.size}' rows")
          return nil
        end
        rows.first
      end

      # TODO: right now type can be different values for insatnce; may cleanup so its set to 'instance'
      def self.object_type_filter
        [:neq, :type, 'template']
      end

      def self.display_name_from_provider_and_region(provider, region)
        "#{provider.base_name()}-#{region}"
      end

      def self.set_builtin_provider_display_fields!(target)
        target.merge!(provider: BuiltinProviderDisplayHash)
      end

      BuiltinProviderDisplayHash = { iaas_type: 'ec2', display_name: 'DTK-BUILTIN' }
    end
  end
end
