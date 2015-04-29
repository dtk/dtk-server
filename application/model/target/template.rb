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

      def self.create_provider?(project_idh, iaas_type, provider_name, iaas_properties_hash, params_hash={}, opts={})
        if existing_provider = provider_exists?(project_idh, provider_name)
          if opts[:raise_error_if_exists]
            raise ErrorUsage.new("Provider (#{provider_name}) exists already")
          else
            return existing_provider
          end
        end

        iaas_properties = IAASProperties.check(iaas_type,iaas_properties_hash)
        
        target_mh = project_idh.createMH(:target)
        display_name = provider_display_name(provider_name)
        ref = display_name.downcase.gsub(/ /,"-")
        create_row = {
          :iaas_type       => iaas_type.to_s,
          :project_id      => project_idh.get_id(),
          :type            => 'template', 
          :ref             => ref, 
          :display_name    => display_name,
          :description     => params_hash[:description],
          :iaas_properties => iaas_properties
        }
        create_opts = {:convert => true, :ret_obj => {:model_name => :target_template}}
        create_from_row(target_mh,create_row,create_opts)
      end

      class DeleteResponse < Hash
        def add_target_response(hash)
          hash.each_pair do |msg_type,msg_array|
            pntr = (self[msg_type] ||= Array.new)
            msg_array.each{|msg|pntr << msg}
          end
          self
        end
      end
      def self.delete_and_destroy(provider,opts={})
        response = DeleteResponse.new()
        unless opts[:force]
          assembly_instances = provider.get_assembly_instances(:omit_empty_workspace => true)
          unless assembly_instances.empty?
            assembly_names = assembly_instances.map{|a|a[:display_name]}.join(',')
            provider_name = provider.get_field?(:display_name)
            raise ErrorUsage.new("Cannot delete provider '#{provider_name}' because service instance(s) (#{assembly_names}) are using one of its targets") 
          end
        end

        target_instances = provider.get_target_instances(:cols => [:display_name,:is_default_target])
        Transaction do
          target_instances.each do |target_instance|
            target_delete_response = Instance.delete_and_destroy(target_instance)
            response.add_target_response(target_delete_response)
          end 
          delete_instance(provider.id_handle())
        end
        response
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
        # DTK-1735 DO NOT copy aws key and secret from provider to target
        common_iaas_properties.delete_if{|k,v| [:key, :secret].include?(k)}

        iaas_properties_list = regions.map do |region|
          name = default_target_name(:region => region)
          properties = common_iaas_properties.merge(:region => region)
          IAASProperties.new(:name => name, :iaas_properties => properties)
        end
        Instance.create_targets?(project_idh,self,iaas_properties_list)
      end

      def get_availability_zones(region)
        CommandAndControl.get_and_process_availability_zones(get_field?(:iaas_type), get_field?(:iaas_properties).merge(:region => region),region)
      end


      def get_assembly_instances(opts={})
        ret = Array.new
        target_instances = id_handle.create_object().get_target_instances()
        unless target_instances.empty?
          ret = Assembly::Instance.get(model_handle(:assembly_instance),:target_idhs => target_instances.map{|t|t.id_handle})
          if opts[:omit_empty_workspace]
            ret.reject! do |assembly|
              if Workspace.is_workspace?(assembly)
                assembly.get_nodes().empty?
              end
            end
          end
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
        # get_field?(:display_name).gsub(Regexp.new("#{DisplayNameSufix}$"),'')
        get_field?(:display_name)
      end

      def self.object_type_filter()
        [:eq,:type,'template']
      end
      
      def self.provider_display_name(provider_name)
        # "#{provider_name}#{DisplayNameSufix}"
        provider_name
      end
      # removed '-template' from provider display_name (ticket DTK-1480)
      # DisplayNameSufix = '-template'

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
