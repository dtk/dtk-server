module DTK
  #This is a provider
  class Target
    class Template < self

      def self.list(target_mh,opts={})
        sp_hash = {
          :cols => common_columns(),
          :filter => [:eq,:type,'template']
        }
        get_objs(target_mh, sp_hash.merge(opts))
      end

      def self.get(target_mh, id)
        target = super(target_mh, id)
        raise ErrorUsage.new("Target with ID '#{id}' is not a template") unless target.is_template?
        target
      end

      def self.create_provider?(project_idh, provider_name, params_hash, opts={})
        if existing_provider = provider_exists?(project_idh, provider_name)
          if opts[:raise_error_if_exists]
            raise ErrorUsage.new("Provider (#{provider_name}) exists already")
          else
            return existing_provider.id_handle()
          end
        end

        # check iaas type
        supported_types = R8::Config[:ec2][:iaas_type][:supported]
        unless supported_types.include?(params_hash[:iaas_type].downcase)
          raise ErrorUsage.new("Invalid iaas type '#{params_hash[:iaas_type]}', supported types (#{supported_types.join(', ')})") 
        end
        # we first check if we are ok with aws credentials
        params_hash[:iaas_properties] = CommandAndControl.prepare_account_for_target(params_hash[:iaas_type].to_s,params_hash[:iaas_properties])
        
        target_mh = project_idh.createMH(:target)
        display_name = provider_display_name(provider_name)
        ref = display_name.downcase.gsub(/ /,"-")
        row = {
          :project_id => project_idh.get_id(),
          :type => 'template', 
          :ref => ref, 
          :display_name => display_name
        }.merge(params_hash)
        create_from_row(target_mh,row,:convert => true) 
      end

      def base_name()
        get_field?(:display_name).gsub(Regexp.new("#{DisplayNameSufix}$"),'')
      end
     private
      def self.provider_display_name(provider_name)
        "#{provider_name}#{DisplayNameSufix}" 
      end
      DisplayNameSufix = '-template'

      def self.provider_exists?(project_idh,provider_name)
        sp_hash = {
          :cols => [:id],
          :filter => [:and,[:eq,:display_name,provider_display_name(provider_name)],
                      [:eq,:project_id,project_idh.get_id()]]
        }
        get_obj(project_idh.createMH(:target),sp_hash)
      end
    end
  end
end
