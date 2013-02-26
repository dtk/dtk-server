module DTK
  class ServiceModule
    r8_nested_require('dsl','assembly_import')
    r8_nested_require('dsl','assembly_export')
    module DSLClassMixin
      def delete_assembly_dsl?(assembly_idh)
        sp_hash = {
          :cols => [:display_name, :module_branch],
          :filter => [:eq,:id,assembly_idh.get_id()]
        }
        assembly_mh = assembly_idh.createMH()
        ndx_module_branches = Hash.new
        get_objs(assembly_mh,sp_hash).each do |r|
          module_branch = r[:module_branch]
          assembly_name = r[:display_name]
          assembly_dir = assembly_meta_directory_path(assembly_name)
          RepoManager.delete_directory?(assembly_dir,module_branch)
          ndx_module_branches[module_branch[:id]] ||= module_branch
        end
        ret = nil
        ndx_module_branches.each_value do |module_branch|
          RepoManager.push_changes(module_branch)
          if module_branch[:is_workspace]
            ret = module_branch.get_module_repo_info()
          end
        end
        ret
      end

      def assembly_meta_directory_path(assembly_name)
        "assemblies/#{assembly_name}"
      end
      def assembly_meta_filename_path(assembly_name)
        "#{assembly_meta_directory_path(assembly_name)}/assembly.json"
      end
    end

    module DSLMixin
      def update_model_from_dsl(module_branch,opts={})
        set_dsl_parsed!(false)
        module_version_constraints = update_global_refs(module_branch,opts)
        update_assemblies_from_dsl(module_branch,module_version_constraints)
        set_dsl_parsed!(true)
      end

     private
      def update_global_refs(module_branch,opts={})
        constraints_hash_form = Hash.new
        meta_filename_path = GlobalModuleRefs.meta_filename_path()
        if json_content = RepoManager.get_file_content(meta_filename_path,module_branch,:no_error_if_not_found=>true)
          constraints_hash_form = Aux.json_parse(json_content,meta_filename_path)
        end
        vconstraints = module_branch.get_module_version_constraints()
        vconstraints.set_and_save_constraints!(constraints_hash_form,opts)
      end

      def update_assemblies_from_dsl(module_branch,module_version_constraints)
        project_idh = get_project.id_handle()
        module_name = module_name()
        module_branch_idh = module_branch.id_handle()
        assembly_dsl_path_info = assembly_dsl_filename_path_info()
        add_on_dsl_path_info = ServiceAddOn.dsl_filename_path_info()
        depth = [assembly_dsl_path_info[:path_depth],add_on_dsl_path_info[:path_depth]].max
        files = RepoManager.ls_r(depth,{:file_only => true},module_branch)
        assembly_import_helper = AssemblyImport.new(project_idh,module_branch,module_name,module_version_constraints)
        dangling_errors = ErrorUsage::DanglingComponentRefs::Aggregate.new(:error_cleanup => proc{error_cleanup()})
        files.select{|f|f =~ assembly_dsl_path_info[:regexp]}.each do |meta_file|
          dangling_errors.aggregate_errors!()  do
            json_content = RepoManager.get_file_content(meta_file,module_branch)
            hash_content = Aux.json_parse(json_content,meta_file)
            assembly_import_helper.process(module_name,hash_content)
          end
        end
        dangling_errors.raise_error?()

        assembly_import_helper.import()
        ports = assembly_import_helper.ports()
        aug_assembly_nodes = assembly_import_helper.augmented_assembly_nodes()
        files.select{|f| f =~ add_on_dsl_path_info[:regexp]}.each do |meta_file|
          json_content = RepoManager.get_file_content({:path => meta_file},module_branch)
          hash_content = Aux.json_parse(json_content,meta_file)
          ServiceAddOn.import(project_idh,module_name,meta_file,hash_content,ports,aug_assembly_nodes)
        end
      end

      def assembly_dsl_filename_path_info()
        {
          :regexp => Regexp.new("^assemblies/[^/]+/assembly.json$"),
          :path_depth => 3
        }
      end

      def error_cleanup()
        #TODO: this is wrong; 
        #ServiceModule.delete(id_handle())
        #determine if there is case where this is appropriate or have delete for other objects; can also case on dsl_parsed
        Log.error("TODO: may need to  write error cleanup for service module update that does not parse for service module (#{update_object!(:display_name,:dsl_parsed).inspect})")
      end
      
    end
  end
end


