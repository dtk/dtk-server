# TODO: trying to better isolate public methods from private ones. Want to go to solution where there is asmall mixin of the public methods
# available on BaseModule subclasses and then these call an embedded object; but for time being keeping all as mixin and 
# inserting __private members
# TODO: useful to seperate out what applies to service modules as well as component,test, etc

# This is the new reformulated items
module DTK; class BaseModule
  class UpdateModule
    r8_nested_require('update_module','import')
    r8_nested_require('update_module','clone_changes')

    ####### public methods #########
    module Mixin
      def import_from_puppet_forge(config_agent_type,impl_obj,component_includes)
        Import.new(self).import_from_puppet_forge(config_agent_type,impl_obj,component_includes)
      end
      
      def import_from_git(commit_sha,repo_idh,version,opts={})
        Import.new(self).import_from_git(commit_sha,repo_idh,version,opts)
      end
      
      def import_from_file(commit_sha,repo_idh,version,opts={})
        Import.new(self).import_from_file(commit_sha,repo_idh,version,opts)
      end

      def update_model_from_clone_changes(commit_sha,diffs_summary,module_branch,version,opts={})
        CloneChanges.new(self).update_from_clone_changes(commit_sha,diffs_summary,module_branch,version,opts)
      end
    end
    ####### end: public methods #########

    def initialize(base_module)
      @base_module = base_module
    end

   private
    def parse_dsl(impl_obj,opts={})
      @base_module.klass().parse_dsl(@base_module,impl_obj,opts)
    end
    def set_dsl_parsed!(boolean)
      @base_module.set_dsl_parsed!(boolean)
    end
    def update_component_module_refs(module_branch,matching_module_refs)
      UpdateModuleRefs.update_component_module_refs(module_branch,matching_module_refs,@base_module.class)
    end
    def module_namespace()
      @base_module.module_namespace()
    end
    def config_agent_type_default()
      @base_module.config_agent_type_default()
    end

    # TODO: when refactor done the methods on @base_module wil be moved to be private isnatnce methods on UpdateModule
    # and these bridge methods removed
    def ret_local(version)
      @base_module.ret_local(version)
    end

    def is_parsing_error?(response)
      @base_module.is_parsing_error?(response)
    end
    def create_needed_objects_and_dsl?(repo,local,opts={})
      @base_module.create_needed_objects_and_dsl?(repo,local,opts)
    end
    def parse_impl_to_create_dsl(config_agent_type,impl_obj,opts={})
      @base_module.parse_impl_to_create_dsl(config_agent_type,impl_obj,opts)
    end

  end
end; end

# items to move to new style
module DTK; class BaseModule; class UpdateModule
  r8_nested_require('update_module','update_module_refs')
  r8_nested_require('update_module','external_refs')
  module Mixin
    include ExternalRefsMixin

    ## TODO: see if any can be moved to being private                                
    ####### public methods #########

    # called when installing from dtkn catalog
    # returns nil or parsing error
    def install__process_dsl(repo,module_branch,local,opts={})
      response = create_needed_objects_and_dsl?(repo,local,opts)
      return response if is_parsing_error?(response)
    end
    

    def pull_from_remote__update_from_dsl(repo, module_and_branch_info,version=nil)
      pull_from_remote__update_from_dsl__private(repo, module_and_branch_info,version)
    end

    def parse_dsl_and_update_model(impl_obj,module_branch_idh,version,opts={})
      parse_dsl_and_update_model__private(impl_obj,module_branch_idh,version,opts)
    end

    def create_new_version__type_specific(repo_for_new_branch,new_version,opts={})
      local = ret_local(new_version)
      create_needed_objects_and_dsl?(repo_for_new_branch,local,opts)
    end

    ####### end: public methods #########

    # TODO: for testing
    def test_generate_dsl()
      module_branch = get_module_branch_matching_version()
      config_agent_type = :puppet
      impl_obj = module_branch.get_implementation()
      parse_impl_to_create_dsl(config_agent_type,impl_obj)
    end
    ### end: for testing

  private    
    def pull_from_remote__update_from_dsl__private(repo, module_and_branch_info,version=nil)
      info = module_and_branch_info #for succinctness
      module_branch_idh = info[:module_branch_idh]
      module_branch = module_branch_idh.create_object().merge(:repo => repo)
      create_needed_objects_and_dsl?(repo,ret_local(version))
    end

    def parse_dsl_and_update_model__private(impl_obj,module_branch_idh,version,opts={})
      set_dsl_parsed!(false)
      ret, tmp_opts = {}, {}
      module_branch = module_branch_idh.create_object()
      config_agent_type = opts[:config_agent_type] || config_agent_type_default()
      dsl_obj = klass().parse_dsl(self,impl_obj,opts.merge(:config_agent_type => config_agent_type))
      return dsl_obj if is_parsing_error?(dsl_obj)

      if opts[:update_from_includes]
        ret = UpdateModuleRefs.new(dsl_obj,self.class).validate_includes_and_update_module_refs()
        return ret if is_parsing_error?(ret)
      end

      dsl_obj.update_model_with_ref_integrity_check(:version => version)
      tmp_opts.merge!(:ambiguous => ret[:ambiguous]) if ret[:ambiguous]
      unless opts[:skip_module_ref_update]
        ret_cmr = ModuleRefs.get_component_module_refs(module_branch)
        if new_commit_sha = ret_cmr.serialize_and_save_to_repo?(tmp_opts)
          if opts[:ret_dsl_updated_info]
            msg = ret[:message]||"The module refs file was updated by the server"
            opts[:ret_dsl_updated_info] = ModuleDSLInfo::UpdatedInfo.new(:msg => msg,:commit_sha => new_commit_sha)
          end
        end
      end

      # parsed will be true if there are no missing or ambiguous dependencies, or flag dsl_parsed_false is not sent from the client
      dependencies = ret[:external_dependencies]||{}
      no_errors = (dependencies[:possibly_missing]||{}).empty? and (ret[:ambiguous]||{}).empty?
      if no_errors and !opts[:dsl_parsed_false]
        set_dsl_parsed!(true)
      end

      opts[:external_dependencies] = dependencies unless dependencies.empty?
      ret unless no_errors
    end


    def add_dsl_content_to_impl(impl_obj,dsl_created_info)
      impl_obj.add_file_and_push_to_repo(dsl_created_info[:path],dsl_created_info[:content])
    end

    # TODO: when refactor finished the methods below wil; be changed to be private instance methods on UpdateModule
   public


    # Rich: DTK-1754 pass in an (optional) option that indicates scaffolding strategy
    # will build in flexibility to support a number of varaints in how Puppet as an example
    # gets mapped to a starting point dtk.model.yaml file
    # Initially we wil hace existing stargey for the top level and
    # completely commented out for the component module dependencies
    # As we progress we can identiy two pieces of info
    # 1) what signatures get parsed (e.g., only top level puppet ones) and put in dtk
    # 2) what signatures get parsed and put in commented out
    def parse_impl_to_create_dsl(config_agent_type,impl_obj,opts={})
      ret = ModuleDSLInfo::CreatedInfo.new()
      parsing_error = nil
      render_hash = nil
      begin
        impl_parse = ConfigAgent.parse_given_module_directory(config_agent_type,impl_obj)
        dsl_generator = ModuleDSL::GenerateFromImpl.create()
        # refinement_hash is version neutral form gotten from version specfic dsl_generator
        refinement_hash = dsl_generator.generate_refinement_hash(impl_parse,module_name(),impl_obj.id_handle())
        render_hash = refinement_hash.render_hash_form(opts)
       rescue ErrorUsage => e
        # parsing_error = ErrorUsage.new("Error parsing #{config_agent_type} files to generate meta data")
        parsing_error = e
       rescue => e
        Log.error_pp([:parsing_error,e,e.backtrace[0..10]])
        raise e
      end
      if render_hash
        format_type = ModuleDSL.default_format_type()
        content = render_hash.serialize(format_type)
        dsl_filename = ModuleDSL.dsl_filename(config_agent_type,format_type)
        ret.merge!(:path=>dsl_filename, :content=> content)
        if opts[:ret_hash_content]
          ret.merge!(:hash_content => render_hash) 
        end
      end
      raise parsing_error if parsing_error
      ret
    end

    def klass()
      case self.class
        when NodeModule
          NodeModuleDSL
        else
          ModuleDSL
      end
    end

    def is_parsing_error?(response)
      ModuleDSL::ParsingError.is_error?(response)
    end

    def ret_local(version)
      local_params = ModuleBranch::Location::LocalParams::Server.new(
        :module_type => module_type(),
        :module_name => module_name(),
        :namespace   => module_namespace(),
        :version     => version
      )
      local_params.create_local(get_project())
    end

    def create_needed_objects_and_dsl?(repo, local, opts={})
      ret = ModuleDSLInfo.new
      # TODO: see if this should be merge! rather than merge
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

      module_and_branch_info = self.class.create_module_and_branch_obj?(project,repo.id_handle(),local,opts[:ancestor_branch_idh])
      module_branch_idh = module_and_branch_info[:module_branch_idh]
      module_branch = module_branch_idh.create_object()

      # process any external refs if one of the flags :process_external_refs,:set_external_refs is true
      opts_external_refs = Aux.hash_subset(opts,[:process_external_refs,:set_external_refs])
      unless opts_external_refs.empty?
        # external_ref if non null ,will have info from the config agent related meta files such as Puppert ModuleFile 
        if external_ref = ConfigAgent.parse_external_ref?(config_agent_type,impl_obj) 
          module_branch.update_external_ref(external_ref[:content]) if external_ref[:content]
          if opts[:process_external_refs]
            external_deps = check_and_ret_external_ref_dependencies?(external_ref,project,module_branch)
            ret.merge!(external_deps)
          end
        end
      end

      dsl_created_info = ModuleDSLInfo::CreatedInfo.new()
      klass = klass()
      if klass.contains_dsl_file?(impl_obj)
        opts_parse = opts.merge(:project => project)
        if err = klass::ParsingError.trap{parse_dsl_and_update_model(impl_obj,module_branch_idh,local.version,opts_parse)}
          ret.dsl_parse_error = err
        end
      elsif opts[:scaffold_if_no_dsl]
        opts_parse = Hash.new
        if ret[:matching_module_refs]
          opts_parse.merge!(:include_modules => ret[:matching_module_refs].map{|r|r.component_module})
        end
        dsl_created_info = parse_impl_to_create_dsl(config_agent_type,impl_obj,opts_parse)
        if opts[:commit_dsl]
          add_dsl_content_to_impl(impl_obj,dsl_created_info)
        end
      end

      ret.set_external_dependencies?(opts[:external_dependencies])

      dsl_updated_info = opts[:ret_dsl_updated_info]
      if dsl_updated_info && !dsl_updated_info.empty?
        ret.dsl_updated_info = dsl_updated_info
      end

      ret.merge(:module_branch_idh => module_branch_idh, :dsl_created_info => dsl_created_info)
    end

  end
end; end; end
