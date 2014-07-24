module DTK
  # This is a provider
  class Target
    class Template < self
      subclass_model :target_template, :target, :print_form => 'provider'

      def self.list(target_mh)
        sp_hash = {
          :cols => common_columns(),
          :filter => object_type_filter()
        }
        get_these_objs(target_mh, sp_hash)
      end

      def self.create_provider?(project_idh, iaas_type, provider_name, params_hash, opts={})
        if existing_provider = provider_exists?(project_idh, provider_name)
          if opts[:raise_error_if_exists]
            raise ErrorUsage.new("Provider (#{provider_name}) exists already")
          else
            return existing_provider
          end
        end

        iaas_properties = IAASProperties.check_and_process(iaas_type,params_hash[:iaas_properties])
        
        target_mh = project_idh.createMH(:target)
        display_name = provider_display_name(provider_name)
        ref = display_name.downcase.gsub(/ /,"-")
        create_row = {
          :iaas_type => iaas_type.to_s,
          :project_id => project_idh.get_id(),
          :type => 'template', 
          :ref => ref, 
          :display_name => display_name
        }.merge(params_hash).merge(:iaas_properties => iaas_properties)
        create_opts = {:convert => true, :ret_obj => {:model_name => :target_template}}
        create_from_row(target_mh,create_row,create_opts)
      end

      def self.delete(provider)
        assembly_instances = provider.get_assembly_instances()
        unless assembly_instances.empty?
          assembly_names = assembly_instances.map{|a|a[:display_name]}.join(',')
          provider_name = provider.get_field?(:display_name)
          raise ErrorUsage.new("Cannot delete provider '#{provider_name}' because service instance(s) (#{assembly_names}) are using one of its targets") 
        end
        
        target_instances = provider.get_target_instances(:cols => [:display_name,:is_default_target])
        if default_target = target_instances.find{|t|t[:is_default_target]}
          provider_name = provider.get_field?(:display_name)
          default_target_name = default_target[:display_name]
          raise ErrorUsage.new("Cannot delete provider '#{provider_name}' because it contains the default target (#{default_target_name})")
        end 

        delete_instance(provider.id_handle())
      end

      def create_bootstrap_targets?(project_idh,region_or_regions=nil)
        # for succinctness
        r = region_or_regions
        regions = 
          if r.kind_of?(Array) then r
          elsif r.kind_of?(String) then [r]
          else R8::Config[:ec2][:regions]
          end
        
        common_iaas_properties = get_field?(:iaas_properties)
        iaas_properties_list = regions.map do |region|
          name = default_target_name(:region => region)
          properties = common_iaas_properties.merge(:region => region)
          IAASProperties.new(:name => name, :iaas_properties => properties)
        end
        Instance.create_targets?(project_idh,self,iaas_properties_list)
      end

      def get_assembly_instances()
        ret = Array.new
        target_instances = id_handle.create_object().get_target_instances()
        unless target_instances.empty?
          ret = Assembly::Instance.get(model_handle(:assembly_instance),:target_idhs => target_instances.map{|t|t.id_handle})
        end
        ret
      end

      def get_target_instances(opts={})
        sp_hash = {
          :cols => add_default_cols?(opts[:cols]),
          :filter => [:eq,:parent_id,id()]
        }
        Target::Instance.get_objs(model_handle(:target_instance),sp_hash)
      end

      # TODO: move to be processed by IAAS specfic
      def default_target_name(hash_params)
        if Aux.has_just_these_keys?(hash_params,[:region])
          "#{base_name()}-#{hash_params[:region]}"
        else
          raise Error.new("Not implemented when hash_parsm keys are: #{hash_params.keys.join(',')}")
        end
      end
     private
      def base_name()
        get_field?(:display_name).gsub(Regexp.new("#{DisplayNameSufix}$"),'')
      end

      def self.object_type_filter()
        [:eq,:type,'template']
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

    end
  end
end
