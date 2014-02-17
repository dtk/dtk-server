module DTK
  class Target
    class Instance < self
      subclass_model :target_instance, :target, :print_form => 'template'

      def self.create_target(project_idh,provider,region,params_hash)
        raise Error.new("Rewrite to use IAASProperties")
        create_targets?(project_idh,provider,[region],params_hash,:raise_error_if_exists=>true).first
      end

      def self.create_targets?(project_idh,provider,iaas_properties_list,opts={})
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
        ret = get_these_objs(target_mh, sp_hash)
        ret.each do |t|
          if t.is_builtin_target?()
            set_builtin_provider_display_fields!(t)
          end
          if t.is_default?()
            t[:display_name] << DefaultTargetMark
          end
        end
        ret
      end

      DefaultTargetMark = '*'      

      def is_builtin_target?()
        get_field?(:parent_id).nil?
      end

     private
      def self.object_type_filter()
        [:eq,:type,'instance']
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
