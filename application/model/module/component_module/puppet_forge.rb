module DTK
  class ComponentModule
    class PuppetForge
      def initialize(project,opts={})
        @project = project
        @base_namespace = opts[:base_namespace] || default_namespace()
      end
      private :initialize

      def self.install_module_and_missing_dependencies(project,puppet_forge_local_copy,opts={})
        new(project,opts).install_module_and_missing_dependencies(puppet_forge_local_copy)
      end
      def install_module_and_missing_dependencies(puppet_forge_local_copy)
        pf_local_copy = puppet_forge_local_copy #for succinctness
        # Check for dependencies; resturns missing_modules, found_modules, dependency_warnings
        missing, found, dw = ComponentModule.cross_reference_modules(
          Opts.new(:project_idh => @project.id_handle()),
          pf_local_copy.module_dependencies                                                                     
        )

        # generate list of modules that need to be created from puppet_forge_local_copy
        pf_modules = pf_local_copy.modules(:remove => found)

        # TODO: DTK-1794 need to pass back in form that can be directly returned to client from controller
        # want to pass back info about what was loaded from puppet forge, what was present but needed, adn any dependency_wanrings
        pf_modules.map{|pf_module|install_module(pf_module)}
      end

     private
      def default_namespace()
        Namespace::default_namespace(@project.model_handle(:namespace)).get_field?(:display_name)
      end        
    
      def install_module(pf_module)
        #TODO: DTK-1754: just put in simple logic here that will put modules in same namespace:
        # if no namespace passed in wil use default one, otehrwise will use what is passed in
        # in this function passed in namespace from client would be under :base_namespace
        
        #TODO: DTK-1754: this is ignoring the module name taht is passed onfor top level module; this should be passed in opts
        # and used just for top level module
        module_name = pf_module.default_local_module_name
        local_params = local_params(module_name,@base_namespace)
        
        # create component module, module branch, repo, and implementation objects
        # module_info has has info about the specfic applicable branch
        # this function also copies and commits files from pf_module.path
        opts_create_mod = Opts.new(
          :local_params      => local_params,
          :config_agent_type => :puppet,
          :copy_files        => {:source_directory => pf_module.path}
        )
        module_and_branch_info = ComponentModule.create_module(@project,module_name,opts_create_mod)

        component_module = module_and_branch_info[:module_idh].create_object()
        repo_id = module_and_branch_info[:module_repo_info][:repo_id]
        repo = repo(repo_id)
        create_needed_objects_and_dsl(pf_module,component_module,repo,local_params)
      end
      
      def local_params(module_name,namespace,opts={})
        version = opts[:version]
        ModuleBranch::Location::LocalParams::Server.new(
          :module_type => :component,
          :module_name => module_name,
          :version     => version,
          :namespace   => namespace
        )
      end

      def create_needed_objects_and_dsl(pf_module,component_module,repo,local_params)
        local = local_params.create_local(@project)
        opts = { 
          :scaffold_if_no_dsl    => true, 
          :do_not_raise          => true, 
          :process_external_refs => false,
          :config_agent_type     => :puppet
        }
        component_module.create_needed_objects_and_dsl?(repo,local,opts)
      end
     
      def repo(repo_id)
        @project.model_handle(:repo).createIDH(:id => repo_id).create_object()
      end
     
    end
  end
end

=begin
old code that will probably nnot need


        #
        # We use installed puppet forge gem and initialize git repo in it, after which we push it to gitolite.
        #

        def push_to_server(project, local_params, pf_module_location, gitolite_remote_url, pf_parent_location)
          local = local_params.create_local(project) 
          branch_name = local.branch_name 
          repo = Grit::Repo.init(pf_module_location)

          # after init we add all and push to our tenant
          repo.remote_add('tenant_upstream', gitolite_remote_url)
          repo.git.pull({},'tenant_upstream')
          repo.git.checkout({:env => {'GIT_WORK_TREE' => pf_module_location} }, branch_name)
          repo.git.add({:env => {'GIT_WORK_TREE' => pf_module_location} },'.')
          repo.git.commit({:env => {'GIT_WORK_TREE' => pf_module_location} }, '-m','Initial Commit')
          repo.git.push({},'-f', 'tenant_upstream', branch_name)

          # get head commit sha
          head_commit_sha = repo.head.commit.id

          # we remove not needed folder after push
          FileUtils.rm_rf(pf_parent_location)

          head_commit_sha
        end
       repo = 
       dsl_info_response = component_module.update_from_initial_create(
          commit_sha,
          id_handle(module_info[:repo_id], :repo),
          version,
          { :scaffold_if_no_dsl => true, :do_not_raise => true, :process_external_refs => true }
        )



#       commit_sha  = PuppetForge::Client.push_to_server(project,local_params,local_params.install_dir, module_info[:repo_url])

       module_id   = module_info[:module_id]
       full_module_name   = module_info[:full_module_name]

      response = component_module.update_from_initial_create_and_commit_dsl(
        commit_sha,
        id_handle(module_info[:repo_id], :repo),                                                                         
        module_info[:module_branch_idh],
        local_params,
        { :scaffold_if_no_dsl => true, :do_not_raise => true, :process_external_refs => true }
      )
raise ErrorUsage.new("got here")
        dsl_info_response.merge(:module_id => module_id, :version => version, :full_module_name => full_module_name, :missing_modules => missing, :found_modules => found)

=end
