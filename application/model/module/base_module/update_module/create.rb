module DTK; class BaseModule; class UpdateModule
  module CreateMixin
    def create_needed_objects_and_dsl?(repo, local, opts={})
      ret = Hash.new
      opts.merge!(:ret_dsl_updated_info => Hash.new)
      project = local.project

      config_agent_type = opts[:config_agent_type] || config_agent_type_default()
      impl_obj = Implementation.create?(project,local,repo,config_agent_type)
      impl_obj.create_file_assets_from_dir_els()

      ret_hash = {
        :name              => module_name(),
        :namespace         => module_namespace(),
        :type              => module_type(),
        :version           => local.version,
        :impl_obj          => impl_obj,
        :config_agent_type => config_agent_type
      }
      ret.merge!(ret_hash)

      module_and_branch_info = @base_module.class.create_module_and_branch_obj?(project,repo.id_handle(),local,opts[:ancestor_branch_idh])
      module_branch_idh = module_and_branch_info[:module_branch_idh]
      module_branch = module_branch_idh.create_object()

      # process any external refs if one of the flags :process_external_refs,:set_external_refs is true
      opts_external_refs = Aux.hash_subset(opts,[:process_external_refs,:set_external_refs])
      unless opts_external_refs.empty?
        # external_ref if non null ,will have info from the config agent related meta files such as Puppert ModuleFile 
        if external_ref = ConfigAgent.parse_external_ref?(config_agent_type,impl_obj) 
          module_branch.update_external_ref(external_ref[:content]) if external_ref[:content]
          if opts[:process_external_refs]
            # check_and_ret_external_ref_dependencies? returns a hash that can have keys: :external_dependencies and :matching_module_refs
            ret.merge!(ExternalRefs.new(@base_module).check_and_ret_external_ref_dependencies?(external_ref,project,module_branch))
          end
        end
      end

      dsl_created_info = ModuleDSLInfo::CreatedInfo.new()
      klass = klass()
      if klass.contains_dsl_file?(impl_obj)
        opts_parse = opts.merge(:project => project)
        if err = klass::ParsingError.trap(:only_return_error=>true){parse_dsl_and_update_model(impl_obj,module_branch_idh,local.version,opts_parse)}
          ret.merge!(:dsl_parse_error => err)
        end
      elsif opts[:scaffold_if_no_dsl]
        opts_parse = Hash.new
        if include_modules = include_modules?(ret[:matching_module_refs],ret[:external_dependencies])
          opts_parse.merge!(:include_modules => include_modules)
        end
        dsl_created_info = ScaffoldImplementation.create_dsl(module_name(),config_agent_type,impl_obj,opts_parse)
        if opts[:commit_dsl]
          add_dsl_content_to_impl(impl_obj,dsl_created_info)
        end
      end

      dsl_updated_info = opts[:ret_dsl_updated_info]
      if dsl_updated_info && !dsl_updated_info.empty?
        ret.merge!(:dsl_updated_info => dsl_updated_info)
      end
      
      ret.merge(:module_branch_idh => module_branch_idh, :dsl_created_info => dsl_created_info)
    end

   private
    def include_modules?(matching_module_refs,external_dependencies)
      ret = nil
      return ret unless matching_module_refs or external_dependencies
      ret = Array.new
      if matching_module_refs
        matching_module_refs.each{|r|ret << r.component_module}
      end
      if external_dependencies
        if missing = external_dependencies.possibly_missing?
          # assuming that each element is of form ns/module or module
          missing.each{|r|ret << r.split('/').last}
        end
        if ambiguous = external_dependencies.ambiguous?
          # ambiguous is has with keys ns/module or module
          # example is {"puppetlabs/stdlib"=>["puppetlabs", "r8"]}}
          ambiguous.each_key{|r|ret << r.split('/').last}
        end
        #TODO: add inconstent elements
      end
      ret.uniq unless ret.empty?
    end

  end
end; end; end
