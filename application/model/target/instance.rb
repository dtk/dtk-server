module DTK
  class Target
    class Instance < self
      subclass_model :target_instance, :target
      #takes values from default aside from ones specfically given in argument
      #this wil only be called when there are no existing targets associated with provider
      def self.create_targets?(project_idh,provider,regions,params_hash,opts={})
        target_mh = project_idh.createMH(:target) 
        unless default = get_default_target(target_mh,[:iaas_type,:iaas_properties,:type])
          raise ErrorUsage.new("Cannot find default target")
        end
        provider_id = provider.id
        create_rows = regions.map do |region|
          display_name = display_name_from_provider_and_region(provider,region)
          ref = display_name.downcase.gsub(/ /,"-")
          el = default.merge(:parent_id => provider_id,:ref => ref, :display_name => display_name).merge(params_hash)
          el.merge(:iaas_properties => (el[:iaas_properties]||Hash.new).merge(:region => region))
        end
        create_opts = {:convert => true, :ret_obj => {:model_name => :target_instance}}
        create_from_rows(target_mh,create_rows,create_opts)
      end

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
        ret = get_objs(target_mh.createMH(:target_instance), sp_hash)
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
     private
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
