#Methods for creating, importing, importing, etc modules
module DTK; class ComponentModule
  module ManagementMixin
    def import__dsl(commit_sha,repo,module_and_branch_info,version, opts={})
      info = module_and_branch_info #for succinctness
      module_branch_idh = info[:module_branch_idh]
      module_branch = module_branch_idh.create_object()
      parsed = create_needed_objects_and_dsl?(repo,version, opts)
      module_branch.set_sha(commit_sha)

      return parsed
    end

    def update_from_initial_create(commit_sha,repo_idh,version,opts={})
      ret = {:dsl_created_info => Hash.new}
      module_branch = get_workspace_module_branch(version)
      pull_was_needed = module_branch.pull_repo_changes?(commit_sha)

      parse_needed = !dsl_parsed?()
      return ret unless pull_was_needed or parse_needed

      repo = repo_idh.create_object()
      create_needed_objects_and_dsl?(repo,version,opts)
    end

    def create_new_dsl_version(new_dsl_integer_version,format_type,module_version)
      unless new_dsl_integer_version == 2
        raise Error.new("component_module.create_new_dsl_version only implemented when target version is 2")
      end
      previous_dsl_version = new_dsl_integer_version-1 
      module_branch = get_module_branch_matching_version(module_version)

      #create in-memory dsl object using old version
      component_dsl = ComponentDSL.create_dsl_object(module_branch,previous_dsl_version)
      #create from component_dsl the new version dsl
      dsl_paths_and_content = component_dsl.migrate(module_name(),new_dsl_integer_version,format_type)
      module_branch.serialize_and_save_to_repo(dsl_paths_and_content)
    end

    def delete_object()
      assembly_templates = get_associated_assembly_templates()
      unless assembly_templates.empty?
        assembly_names = assembly_templates.map{|a|a.display_name_print_form()}
        raise ErrorUsage.new("Cannot delete the component module because the assembly template(s) (#{assembly_names.join(',')}) reference it")
      end

      components = get_associated_component_instances()
      unless components.empty?
        component_names = components.map{|r|r.display_name_print_form(:node_prefix=>true)}
        raise ErrorUsage.new("Cannot delete the component module because the component instance(s) (#{component_names.join(',')}) reference it")
      end

      impls = get_implementations()
      delete_instances(impls.map{|impl|impl.id_handle()})
      repos = get_repos()
      repos.each{|repo|RepoManager.delete_repo(repo)}
      delete_instances(repos.map{|repo|repo.id_handle()})
      delete_instance(id_handle())
      {:module_name => module_name()}
    end

    def delete_version(version)
      module_branch  = get_module_branch_matching_version(version)
      raise ErrorUsage.new("Version '#{version}' for specified component module does not exist") unless module_branch

      #TODO: remove after reading: Rich: get_component_version_constraints has been deprecated and also it applies only to a service module
      #version_constraints = module_branch.get_component_version_constraints()
      #raise ErrorUsage.new("Cannot delete the component module version because the service module(s) '#{version_constraints[:service_module]}' reference it") if version_constraints
      
      id_handle      = module_branch.id_handle()
      implementation = module_branch.get_implementation()
      impl_idh       = implementation.id_handle()

      module_branch.delete_instance(id_handle)
      implementation.delete_instance(impl_idh)
      {:module_name => module_name()}
    end

    def pull_from_remote__update_from_dsl(repo, module_and_branch_info,version=nil)
      info = module_and_branch_info #for succinctness
      module_branch_idh = info[:module_branch_idh]
      module_branch = module_branch_idh.create_object().merge(:repo => repo)

      create_needed_objects_and_dsl?(repo,version)
    end

   private
    def create_new_version__type_specific(repo_for_new_branch,new_version,opts={})
      create_needed_objects_and_dsl?(repo_for_new_branch,new_version,opts)
    end

    def update_model_from_clone__type_specific?(commit_sha,diffs_summary,module_branch,version,opts={})
      update_model_objs_or_create_dsl?(diffs_summary,module_branch,version)
    end

    def create_needed_objects_and_dsl?(repo,version,opts={})
      project = get_project()
      config_agent_type = config_agent_type_default()
      module_name = module_name()
      branch_name = ModuleBranch.workspace_branch_name(project,version)

      impl_obj = Implementation.create_workspace_impl?(project.id_handle(),repo,module_name,config_agent_type,branch_name,version)
      impl_obj.create_file_assets_from_dir_els()

      module_and_branch_info = self.class.create_ws_module_and_branch_obj?(project,repo.id_handle(),module_name,version)
      module_branch_idh = module_and_branch_info[:module_branch_idh]

      dsl_created_info = Hash.new()
      dsl_parsed_info  = Hash.new()

      if ComponentDSL.contains_dsl_file?(impl_obj)
        dsl_parsed_info = parse_dsl_and_update_model(impl_obj,module_branch_idh,version,opts)
      elsif opts[:scaffold_if_no_dsl] 
        dsl_created_info = parse_impl_to_create_dsl(config_agent_type,impl_obj)
      end
      dsl_info = {:module_branch_idh => module_branch_idh, :dsl_created_info => dsl_created_info}
      dsl_info.merge!( :dsl_parsed_info => dsl_parsed_info) if (dsl_parsed_info.is_a?(ErrorUsage::DSLParsing) || dsl_parsed_info.is_a?(ComponentDSL::ObjectModelForm::ParsingError))
      
      dsl_info
    end

    def update_model_objs_or_create_dsl?(diffs_summary,module_branch,version,opts={})
      impl_obj = module_branch.get_implementation()
      #TODO: make more robust to handle situation where diffs dont cover all changes; think can detect by looking at shas
      impl_obj.modify_file_assets(diffs_summary)
      dsl_created_info = Hash.new
      dsl_parsed_info  = Hash.new

      if ModuleVersion::AssemblyModule.string_has_version_format?(version)
        if diffs_summary.meta_file_changed?()
          raise ErrorUsage.new("Modifying dtk meta information in assembly instance is not supported; changes to dtk meta file will not take effect in instance")
        end
        AssemblyModule.finalize_edit_component_module(self,module_branch)
      elsif ComponentDSL.contains_dsl_file?(impl_obj)
        if diffs_summary.meta_file_changed?()
          dsl_parsed_info = parse_dsl_and_update_model(impl_obj,module_branch.id_handle(),version,opts)
        end
      else
        config_agent_type = config_agent_type_default()
        dsl_created_info = parse_impl_to_create_dsl(config_agent_type,impl_obj)
      end

      dsl_info = {:dsl_created_info => dsl_created_info}
      dsl_info.merge!( :dsl_parsed_info => dsl_parsed_info) if(dsl_parsed_info.is_a?(ErrorUsage::DSLParsing) || dsl_parsed_info.is_a?(ComponentDSL::ObjectModelForm::ParsingError))
      
      dsl_info
    end

    def parse_dsl_and_update_model(impl_obj,module_branch_idh,version,opts={})
      #get associated assembly templates before do any updates and use to see if any dangling references
      #within transaction after do update
      aug_component_templates = get_aug_associated_component_templates()
      model_parsed = nil
      Transaction do
        model_parsed = ComponentDSL.parse_and_update_model(impl_obj,module_branch_idh,version, opts)
        #TODO: have ComponentDSL.parse_and_update_model return if any deletes
        #below is teh conservative thing to do if dont know if any deletes
        any_deletes = true
        if opts[:no_deletes_performed]
          any_deletes = false
        end
        if any_deletes
          raise_errors_if_dangling_cmp_refs(aug_component_templates)
        end
      end

      return model_parsed if (model_parsed.is_a?(ErrorUsage::DSLParsing) || model_parsed.is_a?(ComponentDSL::ObjectModelForm::ParsingError))
      set_dsl_parsed!(true)
    end

    def raise_errors_if_dangling_cmp_refs(aug_component_templates)
      #this is called within transaction after any deletes are performed (if any)
      return if aug_component_templates.empty?
      sp_hash = {
        :cols => [:id,:display_name,:group_id],
        :filter => [:oneof, :id, aug_component_templates.map{|r|r[:id]}]
      }
      cmp_template_ids_still_present = Model.get_objs(model_handle(:component),sp_hash).map{|r|r[:id]}
      referenced_cmp_templates = aug_component_templates.reject{|r|cmp_template_ids_still_present.include?(r[:id])}
      unless referenced_cmp_templates.empty?
        raise ErrorUsage::ReferencedComponentTemplates.new(referenced_cmp_templates)
      end
    end
      
  end              
end; end
