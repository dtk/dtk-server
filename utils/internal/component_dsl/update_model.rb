module DTK; class ComponentDSL
  module UpdateModelMixin
    def update_model(opts={})
      input_hash =
        if opts.empty?
          @input_hash
        elsif opts[:version]
          modify_for_version_and_override_attrs(@input_hash,opts[:version],opts[:override_attrs])
        else
          add_component_override_attrs(@input_hash,opts[:override_attrs])
        end
      
      self.class.add_components_from_dsl(@container_idh,@config_agent_type,@impl_idh,input_hash)
    end

    class Parser
      def initialize(impl_idh,module_branch_idh,container_idh)
        @impl_idh = impl_idh
        @module_branch_idh = module_branch_idh
        @container_idh = container_idh
      end
      attr_reader :components_hash,:stored_components_hash
     private
      attr_reader :impl_idh, :module_branch_idh,:container_idh
    end

   private
    def add_component_override_attrs(input_hash,override_attrs)
      if override_attrs
        input_hash.keys.inject(Hash.new()) do |h,k|
          h.merge(k => input_hash[k].merge(override_attrs))
        end
      else
        input_hash
      end
    end

    def modify_for_version_and_override_attrs(input_hash,version,override_attrs)
      (override_attrs ||= {})["version"] ||= version

      input_hash.keys.inject(Hash.new()) do |h,k|
        cmp_info = input_hash[k]
        modified_cmp_info = cmp_info.merge(override_attrs).merge("display_name" => component_display_name_with_version(cmp_info["display_name"],version))
        h.merge(component_ref_with_version(k,version) => modified_cmp_info)
      end
    end

    #TODO: move to more central place
    def component_ref_with_version(ref,version)
      "#{ref}__#{version}"
    end
    def component_display_name_with_version(display_name,version)
      "#{display_name}(#{version})"
    end
  end

  module UpdateModelClassMixin
    def update_model(impl_obj,module_branch_idh,version=nil)
      component_dsl_obj = create_dsl_object_from_impl(impl_obj)
      update_opts = {:override_attrs => {"module_branch_id" => module_branch_idh.get_id()}}
      update_opts.merge!(:version => version) if version
      component_dsl_obj.update_model(update_opts)
    end

   private
    def add_components_from_dsl(container_idh,config_agent_type,impl_idh,dsl_hash,dsl_integer_version=nil)
      dsl_integer_version ||= integer_version(dsl_integer_version)
      module_branch_idh = impl_idh.create_object().get_module_branch().id_handle()
      parser_proc = create_parser_processor(dsl_integer_version,impl_idh,module_branch_idh,container_idh)
      parser_proc.parse_components!(config_agent_type,dsl_hash)
      cmps_hash = parser_proc.components_hash()
      stored_cmps_hash = parser_proc.stored_components_hash()

      #data_source_update_hash form used so can annotate subcomponents with "is complete" so will delete items that are removed
      db_update_hash = db_update_form(cmps_hash,stored_cmps_hash,module_branch_idh)
      Model.input_hash_content_into_model(container_idh,db_update_hash)
      sp_hash =  {
        :cols => [:id,:display_name], 
        :filter => [:and,[:oneof,:ref,cmps_hash.keys],[:eq,:library_library_id,container_idh.get_id()]]
      }
      Model.get_objs(container_idh.create_childMH(:component),sp_hash).map{|r|r.id_handle()}
    end

    def create_parser_processor(dsl_integer_version,impl_idh,module_branch_idh,container_idh)
      klass = load_and_return_version_adapter_class(dsl_integer_version)
      klass.const_get("Parser").new(impl_idh,module_branch_idh,container_idh)
    end
  end
end; end

