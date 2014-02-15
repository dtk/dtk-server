module DTK
  class Target
    class Instance < self
      #takes values from default aside from ones specfically given in argument
      #this wil only be called when there are no existing targets associated with provider
      def self.create_targets(project_idh,provider,regions,params_hash)
        target_mh = project_idh.createMH(:target) 
        unless default = get_default_target(target_mh,[:iaas_type,:iaas_properties,:type])
          raise ErrorUsage.new("Cannot find default target")
        end
        provider_name = provider.get_field?(:display_name)
        provider_id = provider.id
        create_rows = regions.map do |region|
          display_name = "#{provider_name}-#{region}"
          ref = display_name.downcase.gsub(/ /,"-")
          default.merge(:parent_id => provider_id, :region => region, :ref => ref, :display_name => display_name).merge(params_hash)
        end
        create_opts = {:convert => true, :returning_sql_cols => [:id,:display_name]}
        create_from_row(target_mh,create_rows,:create_opts)
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
        ret = get_objs(target_mh, sp_hash)
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
      def self.set_builtin_provider_display_fields!(target)
        target.merge!(:provider => BuiltinProviderDisplayHash)
      end
      
      BuiltinProviderDisplayHash = {:iaas_type=>'ec2', :display_name=>'DTK-BUILTIN'}
    end
  end
end
