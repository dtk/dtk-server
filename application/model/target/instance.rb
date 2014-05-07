module DTK
  class Target
    class Instance < self
      subclass_model :target_instance, :target, :print_form => 'target'

      def self.create_target(project_idh,provider,region,opts={})
        properties = provider.get_field?(:iaas_properties).merge(:region => region)
        target_name = opts[:target_name]|| provider.default_target_name(:region => region)
        iaas_properties = IAASProperties.new(target_name,properties)
        create_targets?(project_idh,provider,[iaas_properties],:raise_error_if_exists=>true).first
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
          el = provider.hash_subset(*InheritedProperties).merge(specific_params)
          #need deep merge for iaas_properties
          el.merge(:iaas_properties => (el[:iaas_properties]||Hash.new).merge(iaas_properties.properties))
        end

        #check if there are any matching target instances that are created already
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
      #These properties are inherited ones for target instance: default provider -> target's provider -> target instance (most specific)
      InheritedProperties = [:iaas_type,:iaas_properties,:type,:description]

      def self.delete(target)
        if target.is_builtin_target?()
          raise ErrorUsage.new("Cannot delete the builtin target")
        end
        delete_instance(target.id_handle())
      end
   
      def self.list(target_mh,opts={})
        filter = [:neq,:type,'template']
        if opts[:filter]
          filter = [:and,filter,opts[:filter]]
        end
        sp_hash = {
          :cols => [:id, :display_name, :iaas_type, :type, :parent_id, :provider, :is_default_target],
          :filter => filter
        }
        unsorted_rows = get_these_objs(target_mh, sp_hash)
        unsorted_rows.each do |t|
          if t.is_builtin_target?()
            set_builtin_provider_display_fields!(t)
          end
          # if t.is_default?()
          #   t[:display_name] << DefaultTargetMark
          # end
        end
        #sort by 1-whether default, 2-iaas_type, 3-display_name 
        unsorted_rows.sort do |a,b|
          [a[:is_default_target] ? 0 : 1, a[:iaas_type], a[:display_name]] <=>
          [b[:is_default_target] ? 0 : 1, b[:iaas_type], b[:display_name]]
        end
      end

      DefaultTargetMark = '*'      

      def is_builtin_target?()
        get_field?(:parent_id).nil?
      end

      def self.import_nodes(target)
        inventory_data_hash = parse_inventory_file(target.id())
        target_idh = target.id_handle()
        
        opts = {:return_info => true}
        Model.import_objects_from_hash(target_idh, {"node" => inventory_data_hash}, opts)
      end

      def self.parse_inventory_file(target_id)
        config_base = Configuration.instance.default_config_base()
        inventory_file = "#{config_base}/inventory.yaml"

        hash = YAML.load_file(inventory_file)
        ret = Hash.new

        hash["nodes"].each do |node_name, data|
          display_name = data["name"]||node_name
          ref = "physical--#{display_name}"
          ret[ref] = {
            :os_identifier => data["type"],
            :display_name => display_name,
            :os_type => data["os_type"],
            :managed => false,
            :external_ref => {:type => "physical", :routable_host_address => node_name, :ssh_credentials => data["ssh_credentials"]}
          }
        end

        ret
      end

     private
      #TODO: right now type can be different values for insatnce; may cleanup so its set to 'instance'
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
