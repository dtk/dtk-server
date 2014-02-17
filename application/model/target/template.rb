module DTK
  #This is a provider
  class Target
    class Template < self
      subclass_model :target_template, :target, :print_form => 'provider'

      def self.name_to_id(model_handle,name)
        filter = [:and, [:eq, :display_name, name], object_type_filter()]
        name_to_id_helper(model_handle,name,:filter => filter)
      end

      def self.check_valid_id(model_handle,id)
        filter = [:and, [:eq, :id, id], object_type_filter()]
        check_valid_id_helper(model_handle,id,filter)
      end

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

        params_hash[:iaas_properties] = IAASProperties.check_and_process(iaas_type,params_hash[:iaas_properties])
        
        target_mh = project_idh.createMH(:target)
        display_name = provider_display_name(provider_name)
        ref = display_name.downcase.gsub(/ /,"-")
        create_row = {
          :iaas_type => iaas_type.to_s,
          :project_id => project_idh.get_id(),
          :type => 'template', 
          :ref => ref, 
          :display_name => display_name
        }.merge(params_hash)
        create_opts = {:convert => true, :ret_obj => {:model_name => :target_template}}
        create_from_row(target_mh,create_row,create_opts)
      end

      def self.delete(provider)
        assembly_instances = provider.get_assembly_instances()
        unless assembly_instances.empty?
          assembly_names = assembly_instances.map{|a|a[:display_name]}.join(',')
          provider_name = provider.get_field?(:display_name)
          raise ErrorUsage.new("Cannot delete provide #{provider_name} because service instance(s) (#{assembly_names}) are using one of its targets") 
        end
        delete_instance(provider.id_handle())
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

      def base_name()
        get_field?(:display_name).gsub(Regexp.new("#{DisplayNameSufix}$"),'')
      end

     private
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

      module IAASProperties
        def self.check_and_process(iaas_type,iaas_properties)
          CommandAndControl.check_and_process_iaas_properties(iaas_type,iaas_properties)
        end
      end

    end
  end
end
