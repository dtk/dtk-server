module DTK
  #This is a provider
  class Target
    class Template < self

      def self.list(target_mh)
        sp_hash = {
          :cols => common_columns(),
          :filter => [:eq,:type,'template']
        }
        get_objs(target_mh.createMH(:target_template), sp_hash)
      end

      def self.get(target_mh, id)
        target = super(target_mh, id)
        raise ErrorUsage.new("Target with ID '#{id}' is not a template") unless target.is_template?
        target.create_subclass_obj(:target_template)
      end

      def self.create_provider?(project_idh, iaas_type, provider_name, params_hash, opts={})
        if existing_provider = provider_exists?(project_idh, provider_name)
          if opts[:raise_error_if_exists]
            raise ErrorUsage.new("Provider (#{provider_name}) exists already")
          else
            return existing_provider
          end
        end

        params_hash[:iaas_properties] = IAASProperties.check_and_process(iaas_type,params_hash[:iaas_properties])
        
        target_mh = project_idh.createMH(:target)
        display_name = provider_display_name(provider_name)
        ref = display_name.downcase.gsub(/ /,"-")
        create_row = {
          :project_id => project_idh.get_id(),
          :type => 'template', 
          :ref => ref, 
          :display_name => display_name
        }.merge(params_hash)
        create_opts = {:convert => true, :ret_obj => {:model_name => :target_template}}
        create_from_row(target_mh,create_row,create_opts)
      end

      def base_name()
        get_field?(:display_name).gsub(Regexp.new("#{DisplayNameSufix}$"),'')
      end

     private
      def get_objs(sp_hash,opts={})
        get_objs_subclass_model(sp_hash,:target_template,opts)
      end
      def self.get_objs(mh,sp_hash,opts={})
        if mh[:model_name] == :target_template
          get_objs_subclass_model(mh.createMH(:target),:target_template,sp_hash,opts)
        else
          super(mh,sp_hash,opts)
        end
      end

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
        get_obj(project_idh.createMH(:target_template),sp_hash)
      end

      module IAASProperties
        def self.check_and_process(iaas_type,iaas_properties)
          CommandAndControl.check_and_process_iaas_properties(iaas_type,iaas_properties)
        end
      end

    end
  end
end
