r8_require('module_mixins')
module DTK
  class ComponentModule < Model
    extend ModuleClassMixin
    include ModuleMixin
#TODO: for testing
    def test_generate_dsl()
      module_name =  update_object!(:display_name)[:display_name]
      matching_branches = get_module_branches_matching_version()
      module_branch =  find_branch(:workspace,matching_branches) || component_module.find_branch(:library,matching_branches)
      config_agent_type = :puppet
      impl_obj = module_branch.get_implementation()
      ComponentModule.parse_impl_to_create_dsl(module_name,config_agent_type,impl_obj)
    end
### end: for testing

    def self.model_type()
      :component_module
    end
    def self.component_type()
      :puppet #hardwired
    end
    def component_type()
      :puppet #hardwired
    end

    def self.delete(idh)
      module_obj = idh.create_object().update_object!(:display_name)
      module_name =  module_obj[:display_name]
      unless module_obj.get_associated_target_instances().empty?
        raise ErrorUsage.new("Cannot delete a module if one or more of its instances exist in a target")
      end
      impls = module_obj.get_implementations()
      delete_instances(impls.map{|impl|impl.id_handle()})
      repos = module_obj.get_repos()
      repos.each{|repo|RepoManager.delete_repo(repo)}
      delete_instances(repos.map{|repo|repo.id_handle()})
      delete_instance(idh)
      {:module_name => module_name}
    end

    def self.create_empty_repo(library_idh,project,module_name)
      raise Error.new("MOD_RESTRUCT: needs to be rewritten") 
      if module_exists?(library_idh,module_name)
        raise ErrorUsage.new("Conflicts with existing library module (#{module_name})")
      end
      module_specific_type = :puppet  #TODO: hard wired
      branch_info = {
        :workspace_branch => ModuleBranch.workspace_branch_name(project),
        :library_branch => ModuleBranch.library_branch_name(library_idh)
      }
      create_opts = {:delete_if_exists => true, :create_branches => branch_info.values}
      repo = create_empty_repo_and_local_clone(library_idh,module_name,module_specific_type,create_opts)
      ModuleRepoInfo.new(repo,module_name,branch_info,library_idh)
    end

    #assumes library repo branch create; it updates this, creates workspace branch and then adds meta to workspace branch so it does
    #not show up in library until user promotes it.
    #TODO: consider whether combined functionality of create_empty_repo and update_repo_and_add_dsl should just create ws branch
    #returns has with key :dsl_created
    def self.update_repo_and_add_dsl(repo_idh,library_idh,project,module_name,version=nil,opts={})
      repo = repo_idh.create_object()
      branch_info = {
        :workspace_branch => ModuleBranch.workspace_branch_name(project),
        :library_branch => ModuleBranch.library_branch_name(library_idh)
      }
      repo.update_for_new_repo(branch_info.values) 
      module_and_mb_info = update_lib_module_objs_and_create_dsl?(repo,library_idh,module_name,version=nil,opts)
      library_mb = module_and_mb_info[:module_branch_idh].create_object()
      module_obj = module_and_mb_info[:module_idh].create_object() 
      {:dsl_created => module_and_mb_info[:dsl_created]}
    end

    def create_new_version(new_version,existing_version=nil)
      unless aug_ws_branch = get_augmented_workspace_branch(existing_version)
        raise ErrorUsage.new("There is no module (#{pp_module_name(existing_version)}) in the workspace")
      end

      #make sure there is a not an existing branch that matches the new one
      #TODO: may also put in check taht version number is greater
      if get_module_branches_matching_version(new_version)
        raise ErrorUsage.new("Version exists already for module (#{pp_module_name(new_version)})")
      end
      project = get_project()
      aug_ws_branch.add_new_branch?(project,new_version)
      repo = aug_ws_branch[:repo]
      self.class.update_ws_module_objs_and_create_dsl?(project,repo,module_name(),new_version)
    end

    def info_about(about)
      case about
       when :components
        get_objs(:cols => [:components]).map do |r|
          cmp = r[:component]
          branch = r[:module_branch]
          {:id => cmp[:id], :display_name => cmp[:display_name].gsub(/__/,"::"),:version => branch.pp_version }
        end.sort{|a,b|"#{a[:version]}-#{a[:display_name]}" <=>"#{b[:version]}-#{b[:display_name]}"}
       else
        raise Error.new("TODO: not implemented yet: processing of info_about(#{about})")        
      end
    end

    def self.get_all_workspace_library_diffs(mh)
      #TODO: not treating versions yet and removing modules wheer component not in workspace
      #TODO: much more efficeint is use bulk version 
      modules = get_objs(mh,{:cols => [:id,:display_name]})
      modules.map do |module_obj|
        diffs = module_obj.workspace_library_diffs()
        {:name => module_obj.pp_module_name(), :id => module_obj[:id], :has_diff => !diffs.empty?} if diffs
      end.compact.sort{|a,b|a[:name] <=> b[:name]}
    end

    def workspace_library_diffs(version=nil)
      matching_branches = get_module_branches_matching_version(version)
      unless ws_branch = find_branch(:workspace,matching_branches)
        return nil
      end

      #check that there is a library branch
      unless lib_branch =  find_branch(:library,matching_branches)
        raise Error.new("No library version exists for module (#{pp_module_name(version)}); try using create-new-version")
      end

      unless lib_branch[:repo_id] == ws_branch[:repo_id]
        raise Error.new("Not supporting case where promoting workspace to library branch when branches are on two different repos")
      end

      repo = id_handle(:model_name => :repo, :id => lib_branch[:repo_id]).create_object()
      repo.diff_between_library_and_workspace(lib_branch,ws_branch)
    end

    def get_associated_target_instances()
      get_objs_uniq(:target_instances)
    end

    #MOD_RESTRUCT: TODO: when deprecate self.list__library_parent(mh,opts={}), sub .list__project_parent for this method
    def self.list(mh,opts)
      if project_id = opts[:project_idh]
        ndx_ret = list__library_parent(mh,opts).inject(Hash.new){|h,r|h.merge(r[:display_name] => r)}
        list__project_parent(opts[:project_idh]).each{|r|ndx_ret[r[:display_name]] ||= r}
        ndx_ret.values.sort{|a,b|a[:display_name] <=> b[:display_name]}
      else
        list__library_parent(mh,opts)
      end
    end
    def self.list__project_parent(project_idh)
      sp_hash = {
        :cols => [:id, :display_name,:version],
        :filter => [:eq, :project_project_id, project_idh.get_id()]
      }
      ndx_module_info = get_objs(project_idh.createMH(:component_module),sp_hash).inject(Hash.new()){|h,r|h.merge(r[:id] => r)}

      #get version info
      sp_hash = {
        :cols => [:component_id,:version],
        :filter => [:and,[:oneof, :component_id, ndx_module_info.keys], [:neq,:is_workspace,true]]
      }
      branch_info = get_objs(project_idh.createMH(:module_branch),sp_hash)
      #join in version info
      branch_info.each do |br|
        mod = ndx_module_info[br[:component_id]]
        version = ((br[:version].nil? or br[:version] == "master") ? "CURRENT" : br[:version])
        mdl = ndx_module_info[br[:component_id]]
        (mdl[:version_array] ||= Array.new) <<  version
      end
      #put version info in prin form
      unsorted = ndx_module_info.values.map do |mdl|
        raw_va = mdl.delete(:version_array)
        unless raw_va.nil? or raw_va == ["CURRENT"]
          version_array = (raw_va.include?("CURRENT") ? ["CURRENT"] : []) + raw_va.reject{|v|v == "CURRENT"}.sort
          mdl.merge!(:version => version_array.join(", ")) #TODO: change to ':versions' after sync with client
        end
        mdl.merge(:type => mdl.component_type())
      end
      unsorted.sort{|a,b|a[:display_name] <=> b[:display_name]}
    end
    #MOD_RESTRUCT: TODO: deprecate below for above
    def self.list__library_parent(mh,opts={})
      library_idh = opts[:library_idh]
      lib_filter = (library_idh ? [:eq, :library_library_id, library_idh.get_id()] : [:neq, :library_library_id, nil])
      sp_hash = {
        :cols => [:id, :display_name,:version],
        :filter => lib_filter
      }
      ndx_module_info = get_objs(mh,sp_hash).inject(Hash.new()){|h,r|h.merge(r[:id] => r)}

      #get version info
      sp_hash = {
        :cols => [:component_id,:version],
        :filter => [:and,[:oneof, :component_id, ndx_module_info.keys], [:neq,:is_workspace,true]]
      }
      branch_info = get_objs(mh.createMH(:module_branch),sp_hash)
      #join in version info
      branch_info.each do |br|
        mod = ndx_module_info[br[:component_id]]
        version = ((br[:version].nil? or br[:version] == "master") ? "CURRENT" : br[:version])
        mdl = ndx_module_info[br[:component_id]]
        (mdl[:version_array] ||= Array.new) <<  version
      end
      #put version info in prin form
      unsorted = ndx_module_info.values.map do |mdl|
        raw_va = mdl.delete(:version_array)
        unless raw_va.nil? or raw_va == ["CURRENT"]
          version_array = (raw_va.include?("CURRENT") ? ["CURRENT"] : []) + raw_va.reject{|v|v == "CURRENT"}.sort
          mdl.merge!(:version => version_array.join(", ")) #TODO: change to ':versions' after sync with client
        end
        mdl.merge(:type => mdl.component_type())
      end
      unsorted.sort{|a,b|a[:display_name] <=> b[:display_name]}
    end

    def create_new_dsl_version(new_dsl_integer_version,format_type)
      module_name =  update_object!(:display_name)[:display_name]
      unless new_dsl_integer_version == 2
        raise Error.new("component_module.create_new_dsl_version only implemeneted when target version is 2")
      end
      previous_dsl_version = new_dsl_integer_version-1 
      matching_branches = get_module_branches_matching_version()
      module_branch =  find_branch(:workspace,matching_branches) || find_branch(:library,matching_branches)

      #create in memory dsl object using old version
      component_dsl = ComponentDSL.create_dsl_object(module_branch,previous_dsl_version)
      #create from component_dsl teh new version dsl
      dsl_paths_and_content = component_dsl.migrate(module_name,new_dsl_integer_version,format_type)
      module_branch.serialize_and_save_to_repo(dsl_paths_and_content)
    end

    #only creates dsl file(s) if one does not exist
    def self.parse_impl_to_create_dsl?(module_name,config_agent_type,impl_obj)
      unless ComponentDSL.contains_dsl_file?(impl_obj)
        parse_impl_to_create_dsl?(module_name,config_agent_type,impl_obj)
      end
    end

    #returns a key with created file's :path and :content 
    def self.parse_impl_to_create_dsl(module_name,config_agent_type,impl_obj)
      parsing_error = nil
      render_hash = nil
      begin
        impl_parse = ConfigAgent.parse_given_module_directory(config_agent_type,impl_obj)
        dsl_generator = ComponentDSL::GenerateFromImpl.create()
        #refinement_hash is neutral form but with version specfic objects fro next phase
        refinement_hash = dsl_generator.generate_refinement_hash(impl_parse,module_name,impl_obj.id_handle())
        render_hash = refinement_hash.render_hash_form()
       rescue ErrorUsage => e
        #parsing_error = ErrorUsage.new("Error parsing #{config_agent_type} files to generate meta data")
         parsing_error = e
      rescue => e
        Log.error_pp([:parsing_error,e,e.backtrace[0..10]])
        raise e
      end
      if render_hash 
        format_type = ComponentDSL.default_format_type()
        content = render_hash.serialize(format_type)
        dsl_filename = ComponentDSL.dsl_filename(config_agent_type,format_type)
        ret = {:path => dsl_filename, :content => content}
      end
      raise parsing_error if parsing_error
      ret
    end
   private
    def update_model_from_clone_changes_aux?(diffs_summary,module_branch,version=nil)
      impl = module_branch.get_implementation()
      if diffs_summary.meta_file_changed?()
        ComponentDSL.update_model(impl,module_branch.id_handle())
      end
    end

    def self.import_postprocess(project,repo,module_name,version)
      update_ws_module_objs_and_create_dsl?(project,repo,module_name,version)[:module_branch_idh]
    end
    
    #returns  hash with keys :module_branch_idh,:dsl_created
    #dsl_created is either nil or hash keys: path, :conent
    #this method does not add the dsl file, but rather passes as argument enabling user to edit then commit
    #creates and updates the module informationa dn optionally creates the dsl depending on :scaffold_if_no_dsl flag in option
    def self.update_ws_module_objs_and_create_dsl?(project,repo,module_name,version=nil,opts={})
      config_agent_type = :puppet #TODO: hard wired
      branch_name = ModuleBranch.workspace_branch_name(project,version)
      impl_obj = Implementation.create_workspace_impl?(project.id_handle(),repo,module_name,config_agent_type,branch_name,version)

      parsing_error = nil
      dsl_created = nil
      if opts[:scaffold_if_no_dsl]
        begin
          dsl_created = parse_impl_to_create_dsl?(module_name,config_agent_type,impl_obj)
         rescue => e
          parsing_error = e
        end
      end
      impl_obj.create_file_assets_from_dir_els()
      module_and_branch_info = create_ws_module_and_branch_obj?(project,repo.id_handle(),module_name,version)
      module_branch_idh = module_and_branch_info[:module_branch_idh]
      raise parsing_error if parsing_error
      #if dsl_created then dont update model (this wil eb done when users optionally edits and commits)
      ComponentDSL.update_model(impl_obj,module_branch_idh,version) unless dsl_created
      {:module_idh => module_and_branch_info[:module_idh], :module_branch_idh => module_branch_idh, :dsl_created => dsl_created}
    end

    #MOD_RESTRUCT: TODO: deprecate below for above

    #returns  hash with keys :module_branch_idh,:dsl_created
    #dsl_created is either nil or hash keys: path, :conent
    #this method does not add the dsl file, but rather passes as argument enabling user to edit then commit
    #creates and updates the module informationa dn optionally creates the dsl depending on :scaffold_if_no_dsl flag in option
    def self.update_lib_module_objs_and_create_dsl?(repo,library_idh,module_name,version=nil,opts={})
      config_agent_type = :puppet #TODO: hard wired
      branch_name = ModuleBranch.library_branch_name(library_idh,version)
      impl_obj = Implementation.create_library_impl?(library_idh,repo,module_name,config_agent_type,branch_name,version)

      parsing_error = nil
      dsl_created = nil
      if opts[:scaffold_if_no_dsl]
        begin
          dsl_created = parse_impl_to_create_dsl?(module_name,config_agent_type,impl_obj)
         rescue => e
          parsing_error = e
        end
      end
      impl_obj.create_file_assets_from_dir_els()
      module_and_branch_info = create_lib_module_and_branch_obj?(library_idh,repo.id_handle(),module_name,version)
      module_branch_idh = module_and_branch_info[:module_branch_idh]
      raise parsing_error if parsing_error
      #if dsl_created then dont update model (this wil eb done when users optionally edits and commits)
      ComponentDSL.update_model(impl_obj,module_branch_idh,version) unless dsl_created
      {:module_idh => module_and_branch_info[:module_idh], :module_branch_idh => module_branch_idh, :dsl_created => dsl_created}
    end

    def export_preprocess(branch)
      #noop
    end
  end
end
