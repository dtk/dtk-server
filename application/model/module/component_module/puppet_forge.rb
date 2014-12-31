

module DTK
  class ComponentModule
    class PuppetForge

      def initialize(project,opts={})
        @project = project
        @base_namespace = opts[:base_namespace] || default_namespace()
        @config_agent_type = :puppet
      end

      private :initialize

      def self.install_module_and_missing_dependencies(project,puppet_forge_local_copy,opts={})
        new(project,opts).install_module_and_missing_dependencies(puppet_forge_local_copy)
      end

      def install_module_and_missing_dependencies(puppet_forge_local_copy)
        pf_local_copy = puppet_forge_local_copy # for succinctness

        # Check for dependencies; resturns missing_modules, found_modules, dependency_warnings
        missing, found_modules, dw = ComponentModule.cross_reference_modules(
          Opts.new(:project_idh => @project.id_handle()),
          pf_local_copy.module_dependencies
        )

        # generate list of modules that need to be created from puppet_forge_local_copy
        pf_modules = pf_local_copy.modules(:remove => found_modules)

        installed_modules = pf_modules.collect { |pf_module| install_module(pf_module) }

        # pass back info about
        # - what was loaded from puppet forge,
        # - what was present but needed, and
        # - any dependency_warnings
        # TODO: DTK-1794; below does not deal with dependency warnings
        format_response(installed_modules, found_modules)
      end

     private

      def default_namespace()
        Namespace.default_namespace_name()
      end

      def install_module(pf_module)
        # TODO: DTK-1754: this is ignoring the module name taht is passed onfor top level module; this should be passed in opts
        # and used just for top level module
        module_name = pf_module.default_local_module_name

        # dependencies user their own namespace
        namespace    = pf_module.is_dependency ? pf_module.namespace : @base_namespace
        local_params = local_params(module_name, namespace)

        module_objs = create_module_objects(local_params,pf_module)

        impl_obj = module_objs[:implementation]
        impl_obj.create_file_assets_from_dir_els()

        module_objs[:component_module].parse_impl_to_create_and_add_dsl(@config_agent_type,impl_obj)
        module_objs[:component_module].set_dsl_parsed!(true)

        pf_module
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

      def create_module_objects(local_params,pf_module)
        opts_create_mod = Opts.new(
          :config_agent_type => @config_agent_type,
          :copy_files        => {:source_directory => pf_module.path}
        )

        module_and_branch_info = ComponentModule.create_module(@project,local_params,opts_create_mod)

        # TODO: more efficient if we got ComponentModule.create_module to pass impl_obj
        # to pass the implementation object that it creates
        repo = repo(module_and_branch_info[:module_repo_info][:repo_id])
        impl_obj = Implementation.create?(@project,local_params,repo,@config_agent_type)
        {
          :component_module => module_and_branch_info[:module_idh].create_object(),
          :implementation   => impl_obj
        }
      end

      def repo(repo_id)
        @project.model_handle(:repo).createIDH(:id => repo_id).create_object()
      end

      def format_response(installed_modules, found_modules)
        main_module = installed_modules.find { |im| !im.is_dependency }
        main_module.namespace = @base_namespace
        {
          :main_module       => main_module.to_h,
          :installed_modules => (installed_modules - [main_module]).collect { |im| im.to_h },
          :found_modules     => found_modules
        }
      end
    end
  end
end
