module DTK
  class Target
    class Instance < self
      subclass_model :target_instance, :target, :print_form => 'target'

      def iaas_properties()
        IAASProperties.new(:target_instance => self)
      end

      def self.create_target(project_idh,provider,region,opts={})
        provider_properties = provider.get_field?(:iaas_properties).merge(:region => region)
        # # DTK-1735 DO NOT copy aws key and secret from provider to target
        properties      = {:region => region}
        provider_type   = provider.get_field?(:iaas_type)
        iaas_properties = []

        if iaas_props = opts[:iaas_properties]
          # remove security_groups from provider and use params provided with create-target
          properties.delete_if{|k,v| [:security_group, :security_group_set].include?(k)}

          # convert params "keypair" to :keypair and "security_group" to :security_group and merge to properties
          properties.merge!(iaas_props.inject({}){|prop,(k,v)| prop[k.to_sym] = v; prop})
        end

        unless region
          raise ErrorUsage.new("Region is required for target created in '#{provider_type}' provider type!") unless provider_type.eql?('physical')
        end

        target_name = opts[:target_name]|| provider.default_target_name(:region => region)
        availability_zones = CommandAndControl.get_and_process_availability_zones(provider_type, provider_properties, region)

        # add iaas_properties for target without availability zone
        iaas_properties << IAASProperties.new(:name => target_name, :iaas_properties => properties)

        # add iass_properties for targets created separately for every availability zone
        availability_zones.each do |az|
          custom_properties = properties.clone
          custom_properties[:availability_zone] = az
          iaas_properties << IAASProperties.new(:name => "#{target_name}-#{az}", :iaas_properties => custom_properties)
        end

        # iaas_properties = IAASProperties.new(:name => target_name, :iaas_properties => properties)
        # create_targets?(project_idh,provider,[iaas_properties],:raise_error_if_exists=>true).first
        create_targets?(project_idh,provider,iaas_properties,:raise_error_if_exists=>true).first
      end

      def self.create_targets?(project_idh,provider,iaas_properties_list,opts={})
        ret = Array.new
        target_mh = project_idh.createMH(:target) 
        provider.update_obj!(*InheritedProperties)
        provider_id = provider.id
        create_rows = iaas_properties_list.map do |iaas_properties|
          display_name = iaas_properties.name
          ref = display_name.downcase.gsub(/ /,"-")
          specific_params = {
            :parent_id => provider_id,
            :ref => ref, 
            :display_name => display_name,
            :type => 'instance'
          }

          # DTK-1735 and DTK-1711 DO NOT use iaas_properties from provider
          # user region, keypair and security_groups provided by user
          # el = provider.hash_subset(*InheritedProperties).merge(specific_params)
          el = provider.hash_subset(:iaas_type,:type,:description).merge(specific_params)

          # need deep merge for iaas_properties
          el.merge(:iaas_properties => iaas_properties.properties)
        end

        # check if there are any matching target instances that are created already
        disjunct_array = create_rows.map do |r|
          [:and, [:eq, :parent_id, r[:parent_id]], 
           [:eq, :display_name, r[:display_name]]]
        end
        sp_hash = {
          :cols => [:id,:display_name,:parent_id],
          :filter => [:or] + disjunct_array
        }
        existing_targets = get_these_objs(target_mh,sp_hash)
        unless existing_targets.empty?
          if opts[:raise_error_if_exists]
            existing_names = existing_targets.map{|et|et[:display_name]}.join(',')
            obj_type = pp_object_type(existing_targets.size)
            raise ErrorUsage.new("The #{obj_type} (#{existing_names}) exist(s) already")
          else
            create_rows.reject! do |r|
              parent_id = r[:parent_id]
              name = r[:display_name]
              existing_targets.find{|et|et[:parent_id] == parent_id and et[:display_name] == name}
            end
          end
        end

        return ret if create_rows.empty?
        create_opts = {:convert => true, :ret_obj => {:model_name => :target_instance}}
        create_from_rows(target_mh,create_rows,create_opts)
      end
      # These properties are inherited ones for target instance: default provider -> target's provider -> target instance (most specific)
      InheritedProperties = [:iaas_type,:iaas_properties,:type,:description]

      def self.delete(target)
        if target.is_builtin_target?()
          raise ErrorUsage.new("Cannot delete the builtin target")
        end
        delete_instance(target.id_handle())
      end

      def self.edit_target(target,iaas_properties)
        target.update_obj!(:iaas_properties)
        current_properties = target[:iaas_properties]

        # convert string keys to symbols ({'keypair' => 'default'} to {:keypair => 'default'})
        iaas_properties = iaas_properties.inject({}){|memo,(k,v)| memo[k.to_sym] = v; memo}

        # avoid having security_group and security_group_set in one iaas_properties
        if iaas_properties[:security_group_set] || iaas_properties[:security_group]
          current_properties.delete(iaas_properties[:security_group] ? :security_group_set : :security_group)
        end

        hash_assignments = {:iaas_properties => current_properties.merge(iaas_properties)}
        Model.update_from_hash_assignments(target.id_handle(),hash_assignments)
      end
   
      def self.list(target_mh,opts={})
        filter = [:neq,:type,'template']
        if opts[:filter]
          filter = [:and,filter,opts[:filter]]
        end
        sp_hash = {
          :cols => [:id, :display_name, :iaas_type, :type, :parent_id, :iaas_properties, :provider, :is_default_target],
          :filter => filter
        }
        unsorted_rows = get_these_objs(target_mh, sp_hash)
        unsorted_rows.each do |t|
          if t.is_builtin_target?()
            set_builtin_provider_display_fields!(t)
          end
          if t[:iaas_properties]
            t[:iaas_properties][:security_group] ||=
              t[:iaas_properties][:security_group_set].join(',') if t[:iaas_properties][:security_group_set]
          end
          # if t.is_default?()
          #   t[:display_name] << DefaultTargetMark
          # end
        end
        # sort by 1-whether default, 2-iaas_type, 3-display_name 
        unsorted_rows.sort do |a,b|
          [a[:is_default_target] ? 0 : 1, a[:iaas_type], a[:display_name]] <=>
          [b[:is_default_target] ? 0 : 1, b[:iaas_type], b[:display_name]]
        end
      end

      DefaultTargetMark = '*'      

      def is_builtin_target?()
        get_field?(:parent_id).nil?
      end

      def self.import_nodes(target, inventory_data)
        Node::TargetRef.create_nodes_from_inventory_data(target, inventory_data)
      end

     private
      # TODO: right now type can be different values for insatnce; may cleanup so its set to 'instance'
      def self.object_type_filter()
        [:neq,:type,'template']
      end

      def self.display_name_from_provider_and_region(provider,region)
        "#{provider.base_name()}-#{region}"
      end

      def self.set_builtin_provider_display_fields!(target)
        target.merge!(:provider => BuiltinProviderDisplayHash)
      end
      
      BuiltinProviderDisplayHash = {:iaas_type=>'ec2', :display_name=>'DTK-BUILTIN'}
    end
  end
end
