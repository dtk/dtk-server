# This can import multiple modules; it uses Import.import_puppet_forge_module to import each moodule that
# needs to be installed
module DTK; class BaseModule; class UpdateModule
  class PuppetForge
    def initialize(project,pf_local_copy,opts={})
      @project           = project
      @pf_local_copy     = pf_local_copy
      @base_namespace    = opts[:base_namespace] || default_namespace()
      @config_agent_type = :puppet
    end

    def import_module_and_missing_dependencies()
      # Check for dependencies; resturns missing_modules, found_modules, dependency_warnings
      missing, found_modules, dw = ComponentModule.cross_reference_modules(
        Opts.new(:project_idh => @project.id_handle()),
        @pf_local_copy.module_dependencies
      )
      # generate list of modules that need to be created from puppet_forge_local_copy
      pf_modules = @pf_local_copy.modules(:remove => found_modules)

      installed_modules = pf_modules.collect{|pf_module|import_module(pf_module)}

      # pass back info about
      # - what was loaded from puppet forge,
      # - what was present but needed, and
      # - any dependency_warnings

      format_response(installed_modules, found_modules)
    end

   private

    def default_namespace()
      Namespace.default_namespace_name()
    end

     def import_module(pf_module)
      params_opts = {}
      module_name = pf_module.default_local_module_name

      MessageQueue.store(:info, "Parsing puppet forge module '#{module_name}' ...")

      # dependencies user their own namespace
      namespace        = pf_module.is_dependency ? pf_module.namespace : @base_namespace
      source_directory = pf_module.path
      cmr_update_els   = component_module_refs_dsl_form_els(pf_module.dependencies)

      params_opts.merge!(:source_name => pf_module.module_source_name) if pf_module.module_source_name
      local_params     = local_params(module_name, namespace, params_opts)
      module_id        = Import.import_puppet_forge_module(@project,local_params,source_directory,cmr_update_els)

      # set id for puppet-forge modules because they will be used on client side to clone modules to local machine
      pf_module.set_id(module_id)
      pf_module
    end

   def component_module_refs_dsl_form_els(dependencies)
     ret = ModuleRefs::ComponentDSLForm::Elements.new
     dependencies.each{|dep|ret << ModuleRefs::ComponentDSLForm.new(dep.name,dep.namespace)}
     ret
    end

    def local_params(module_name, namespace, opts={})
      version     = opts[:version]
      source_name = opts[:source_name]
      ModuleBranch::Location::LocalParams::Server.new(
        :module_type => :component_module,
        :module_name => module_name,
        :version     => version,
        :namespace   => namespace,
        :source_name => source_name
      )
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
end; end; end

