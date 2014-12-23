module DTK
  class ComponentModule
    module PuppetForge
      def self.install_module_and_missing_dependencies(project,puppet_forge_local_copy,opts={})
        pf_local_copy = puppet_forge_local_copy #for succinctness
        # Check for dependencies; resturns missing_modules, found_modules, dependency_wranings
        missing, found, dw = ComponentModule.cross_reference_modules(
            Opts.new(:project_idh => project.id_handle()),
            pf_local_copy.module_dependencies
            )
        # generate list of modules that need to be created from puppet_forge_local_copy
        pf_modules = pf_local_copy.modules(:remove => found)

        base_namespace = opts[:base_namespace] || default_namespace(project)
        pf_modules.map{|pf_module|install_module(project,pf_module,base_namespace,opts)}
      end

     private
      def self.default_namespace(project)
        Namespace::default_namespace(project.model_handle(:namespace)).get_field?(:display_name)
      end        
    
      def self.install_module(project,pf_module,base_namespace,opts={})
        #TODO: DTK-1754: just put in simple logic here that will put modules in same namespace:
        # if no namespace passed in wil use default one, otehrwise will use what is passed in
        # in this function passed in namespace from client would be under :base_namespace

        #TODO: DTK-1754: this is ignoring the module name taht is passed onfor top level module; this should be passed in opts
        # and used just for top level module
        module_name = pf_module.default_local_module_name
        # create component module and moduel branch objects
        opts_create_mod = Opts.new(
          :local_params => local_params(module_name,base_namespace,opts),
          :config_agent_type => opts[:config_agent_type]                                   
        )
       # module_info has has info about the specfic applicable branch
       module_info = ComponentModule.create_module(project,module_name,opts_create_mod)[:module_repo_info]


#       commit_sha  = PuppetForge::Client.push_to_server(project,local_params,local_params.install_dir, module_info[:repo_url])

       module_id   = module_info[:module_id]
       full_module_name   = module_info[:full_module_name]

       component_module = get_obj(module_id)

       version = local_params.version

      # DTK-1754: Rich: put in different call (update_from_initial_create_and_commit_dsl) 
      # than update_from_initial_create which is combination of update_from_initial_create
      # and update_model_from_clone_changes?
#      dsl_info_response = component_module.update_from_initial_create(
#          commit_sha,
#          id_handle(module_info[:repo_id], :repo),
#          version,
#          { :scaffold_if_no_dsl => true, :do_not_raise => true, :process_external_refs => true }
#        )
      response = component_module.update_from_initial_create_and_commit_dsl(
        commit_sha,
        id_handle(module_info[:repo_id], :repo),                                                                         
        module_info[:module_branch_idh],
        local_params,
        { :scaffold_if_no_dsl => true, :do_not_raise => true, :process_external_refs => true }
      )
raise ErrorUsage.new("got here")
        dsl_info_response.merge(:module_id => module_id, :version => version, :full_module_name => full_module_name, :missing_modules => missing, :found_modules => found)
      end

      def self.local_params(module_name,namespace,opts={})
        version = opts[:version]
        ModuleBranch::Location::LocalParams::Server.new(
          :module_type => :component,
          :module_name => module_name,
          :version     => version,
          :namespace   => namespace
        )
      end

    end
  end
end
