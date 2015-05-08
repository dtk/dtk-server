module DTK
  class Target
    class Instance < self
      r8_nested_require('instance','default_target')

      subclass_model :target_instance, :target, :print_form => 'target'

      def info()
        target =  get_obj(:cols => [:display_name,:iaas_type,:iaas_properties,:is_default_target,:provider])
        IAASProperties.sanitize_and_modify_for_print_form!(target[:iaas_type],target[:iaas_properties])
        if provider_name = (target[:provider]||{})[:display_name]
          target[:provider_name] = provider_name
        end
        OrderedInfoKeys.inject(Hash.new) do |h,k|
          val = target[k]
          val.nil? ? h : h.merge(k => val)
        end
      end
      OrderedInfoKeys = [:display_name,:id,:provider_name,:iaas_properties,:is_default_target]

      def iaas_properties()
        IAASProperties.new(:target_instance => self)
      end

      def get_target_running_nodes()
        Node::TargetRef.get_target_running_nodes(self)
      end

      # These properties are inherited ones for target instance: default provider -> target's provider -> target instance (most specific)
      InheritedProperties = [:iaas_type,:iaas_properties,:type,:description]

      def self.create_target_ec2(project_idh,provider,ec2_type,property_hash,opts={})
        unless region = property_hash[:region]
          raise ErrorUsage.new("Region is required for target created in '#{provider.get_field?(:iaas_type)}' provider type!")
        end

        target_name = opts[:target_name]|| provider.default_target_name(:region => region)

        # proactively getting needed columns on provider
        provider.update_obj!(*InheritedProperties)

        # raises errors if problems with any params
        iaas_properties_array = IAASProperties::Ec2.check_and_compute_needed_iaas_properties(target_name,ec2_type,provider,property_hash)

        create_targets?(project_idh,provider,iaas_properties_array,:raise_error_if_exists=>true).first
      end

      def self.create_targets?(project_idh,provider,iaas_properties_array,opts={})
        ret = Array.new
        target_mh = project_idh.createMH(:target) 
        provider.update_obj!(*InheritedProperties)
        provider_id = provider.id
        create_rows = iaas_properties_array.map do |iaas_properties|
          display_name = iaas_properties.name
          ref = display_name.downcase.gsub(/ /,"-")
          specific_params = {
            :parent_id => provider_id,
            :ref => ref, 
            :display_name => display_name,
            :type => 'instance'
          }

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

      class DeleteResponseObject
        def initialize(target)
          @target_name = target.get_field?(:display_name)
          @info        = Hash.new
        end
        def add_info_changed_default_target!(new_default_target)
          @info[:changed_default_target] = new_default_target
        end
        def add_info_changed_workspace_target!(new_default_target)
          @info[:changed_workspace_target] = new_default_target
        end
        
        def hash_form()
          ret = Hash.new
          return ret if @info.empty?()
          default_target = @info[:changed_default_target] 
          workspace_target = @info[:changed_workspace_target]
          if default_target and workspace_target and default_target.id == workspace_target.id 
            add_changed_target!(ret,default_target,:default_and_workspace)
          else
            add_changed_target!(ret,default_target,:default) if default_target
            add_changed_target!(ret,workspace_target,:workspace) if workspace_target
          end
          ret
        end
        private
         def  add_changed_target!(ret,new_target,role)
           new_target_name = new_target.get_field?(:display_name)
           this_setting = (role == :default_and_target ? 'these target settings' : 'this target setting')
           role_str = role.to_s.gsub(/_/,' ')
           msg = "Deleted '#{@target_name}' that was #{role_str} target; changed #{this_setting} to '#{new_target_name}'"
           (ret[:info] ||= Array.new) << msg
           ret
         end
      end

      # returns hash that has response info
      def self.delete_and_destroy(target)
        response_obj = DeleteResponseObject.new(target)
        if target.is_builtin_target?()
          raise ErrorUsage.new("Cannot delete the builtin target") 
        end

        target_mh              = target.model_handle()
        builtin_target         = get_builtin_target(target_mh)
        current_default_target = DefaultTarget.get(target_mh)

        Transaction do
          # change default target if pointing to this target
          if current_default_target and current_default_target.id == target.id
            response_obj.add_info_changed_default_target!(builtin_target)
            DefaultTarget.set(builtin_target,:current_default_target => current_default_target,:update_workspace_target => false)
          end

          assemblies = Assembly::Instance.get(target.model_handle(:assembly_instance),:target_idh => target.id_handle())
          assemblies.each do |assembly|
            if workspace = Workspace.workspace?(assembly)
              # modify workspace target if it points to the one being deleted
              if current_workspace_target = workspace.get_target()
                if current_workspace_target.id == target.id
                  response_obj.add_info_changed_workspace_target!(builtin_target)
                  workspace.set_target(builtin_target, :mode => :from_delete_target) 
                end
              end

              workspace.purge(:destroy_nodes => true)
            else
              Assembly::Instance.delete(assembly.id_handle,:destroy_nodes => true)
            end
          end
          delete_instance(target.id_handle())
        end
        response_obj.hash_form()
      end

      def self.set_default_target(target,opts={})
        current_default_target = DefaultTarget.set(target,opts)
        ResponseInfo.info("Default target changed from ?current_default_target to ?new_default_target",
                          :current_default_target => current_default_target,
                          :new_default_target => target)
      end


      def self.get_default_target(target_mh,cols=[]) 
        DefaultTarget.get(target_mh,cols)
      end      

      def self.set_properties(target,iaas_properties)
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
          IAASProperties.sanitize_and_modify_for_print_form!(t[:iaas_type],t[:iaas_properties])
          if provider = t[:provider]
            IAASProperties.sanitize_and_modify_for_print_form!(provider[:iaas_type],provider[:iaas_properties])
            # modifies iaas_type to make more specfic
            if specific_iaas_type = IAASProperties.more_specific_type?(t[:iaas_type],t[:iaas_properties])
              provider[:iaas_type] = specific_iaas_type
            end
          end
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
      def self.get_builtin_target(target_mh)
        sp_hash = {
          :cols => [:id,:group_id,:display_name],
          :filter => [:and,[:eq,:parent_id,nil],[:eq,:type,'staging']]
        }
        rows = get_objs(target_mh,sp_hash)
        unless rows.size == 1
          Log.error("Unexpected that get_builtin_target returned '#{rows.size.to_s}' rows")
          return nil
        end
        rows.first
      end

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
