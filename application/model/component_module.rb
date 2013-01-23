r8_require('module_mixins')
module DTK
  class ComponentModule < Model
    r8_nested_require('component_module','parse_to_create_dsl')
    extend ModuleClassMixin
    include ModuleMixin
    extend ParseToCreateDSLClassMixin
    include ParseToCreateDSLMixin

    def self.model_type()
      :component_module
    end
    def self.component_type()
      :puppet #hardwired
    end
    def component_type()
      :puppet #hardwired
    end

    def get_associated_assembly_templates()
      ndx_ret = Hash.new
      get_objs(:cols => [:assembly_templates]).each do |r|
        assembly_template = r[:assembly_template]
        ndx_ret[assembly_template[:id]] ||= Assembly::Template.create_as(assembly_template)
      end
      ndx_ret.values
    end

    def get_associated_component_instances()
      ndx_ret = Hash.new
      get_objs(:cols => [:component_instances]).each do |r|
        component = r[:component]
        ndx_ret[component[:id]] ||= component
      end
     ndx_ret.values
    end

    def self.delete(idh)
      module_obj = idh.create_object().update_object!(:display_name)
      module_name =  module_obj[:display_name]

      assembly_templates = module_obj.get_associated_assembly_templates()
      unless assembly_templates.empty?
        assembly_names = assembly_templates.map{|a|a.display_name_print_form()}
        raise ErrorUsage.new("Cannot delete the component module because the assembly template(s) (#{assembly_names.join(',')}) reference it")
      end

      components = module_obj.get_associated_component_instances()
      unless components.empty?
        component_names = components.map{|r|r.display_name_print_form(:node_prefix=>true)}
        raise ErrorUsage.new("Cannot delete the component module because the component instance(s) (#{component_names.join(',')}) reference it")
      end

      impls = module_obj.get_implementations()
      delete_instances(impls.map{|impl|impl.id_handle()})
      repos = module_obj.get_repos()
      repos.each{|repo|RepoManager.delete_repo(repo)}
      delete_instances(repos.map{|repo|repo.id_handle()})
      delete_instance(idh)
      {:module_name => module_name}
    end

    def self.module_specific_type(config_agent_type)
      config_agent_type
    end

    def create_new_version(new_version)
      unless aug_ws_branch = get_augmented_workspace_branch()
        raise ErrorUsage.new("There is no module (#{pp_module_name()}) in the workspace")
      end

      #make sure there is a not an existing branch that matches the new one
      if get_module_branch_matching_version(new_version)
        raise ErrorUsage.new("Version exists already for module (#{pp_module_name(new_version)})")
      end
      #TODO: may check that version number is greater than existing versions

      project = get_project()
      aug_ws_branch.add_workspace_branch?(project,new_version)
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
      unless ws_branch = get_module_branch_matching_version(version)
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
        :cols => [:id, :display_name],
        :filter => [:eq, :project_project_id, project_idh.get_id()]
      }
      ndx_module_info = get_objs(project_idh.createMH(:component_module),sp_hash).inject(Hash.new()){|h,r|h.merge(r[:id] => r)}

      #get version info
      sp_hash = {
        :cols => [:component_id,:version],
        :filter => [:and,[:oneof, :component_id, ndx_module_info.keys], [:eq,:is_workspace,true]]
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
      module_branch = get_module_branch_matching_version()

      #create in memory dsl object using old version
      component_dsl = ComponentDSL.create_dsl_object(module_branch,previous_dsl_version)
      #create from component_dsl teh new version dsl
      dsl_paths_and_content = component_dsl.migrate(module_name,new_dsl_integer_version,format_type)
      module_branch.serialize_and_save_to_repo(dsl_paths_and_content)
    end
    #creates workspace branch and then adds meta to it


    def update_repo_and_add_dsl_data(commit_sha,repo_idh,version,opts={})
      ret = {:dsl_created => nil}
      ws_branch = get_workspace_module_branch(version)
      unless ws_branch.is_set_to_sha?(commit_sha)
        pull_clone_changes?(ws_branch,version)
      end

      unless opts[:scaffold_if_no_dsl]
        return ret
      end

      parse_info = parse_impl_to_create_and_push_dsl?(commit_sha,repo_idh,version)
      new_commit_sha = parse_info[:new_commit_sha]
      if new_commit_sha and new_commit_sha != commit_sha
        ws_branch.set_sha(new_commit_sha)      
      end
      {:dsl_created => parse_info[:dsl_created], :commit_sha => new_commit_sha}
    end

   private
    def update_model_from_clone_changes_aux?(diffs_summary,module_branch,version=nil)
      impl = module_branch.get_implementation()
      if diffs_summary.meta_file_changed?()
        ComponentDSL.update_model(impl,module_branch.id_handle())
      end
    end

    def self.import_postprocess(project,repo,module_name,version)
      module_and_branch_info = update_ws_module_objs_and_create_dsl?(project,repo,module_name,version)
      module_branch = module_and_branch_info[:module_branch_idh].create_object()
      module_idh = module_and_branch_info[:module_idh]
      ModuleRepoInfo.new(repo,module_name,module_idh,module_branch,version)
    end
    
    #returns  hash with keys :module_branch_idh,:dsl_created
    #dsl_created is either nil or hash keys: path, :content
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
          parse_impl_to_create_dsl?(module_name,config_agent_type,impl_obj)
          dsl_created = true
         rescue => e
          parsing_error = e
        end
      end
      impl_obj.create_file_assets_from_dir_els()
      module_and_branch_info = create_ws_module_and_branch_obj?(project,repo.id_handle(),module_name,version)
      module_branch_idh = module_and_branch_info[:module_branch_idh]
      raise parsing_error if parsing_error
      #if dsl_created then dont update model (this will be done when users optionally edits and commits)
      ComponentDSL.update_model(impl_obj,module_branch_idh,version) unless dsl_created
      {:module_idh => module_and_branch_info[:module_idh], :module_branch_idh => module_branch_idh, :dsl_created => dsl_created}
    end

    def export_preprocess(branch)
      #noop
    end
  end
end
