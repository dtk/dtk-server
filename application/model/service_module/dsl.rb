module DTK
  class ServiceModule
    r8_nested_require('dsl','assembly_import')
    module DSLClassMixin
      def delete_assembly_dsl?(assembly_idh)
        delete_assemblies_dsl?([assembly_idh])
      end
      def delete_assemblies_dsl?(assembly_idhs)
        return if assembly_idhs.empty?
        sp_hash = {
          :cols => [:display_name, :module_branch],
          :filter => [:oneof,:id,assembly_idhs.map{|idh|idh.get_id()}]
        }
        assembly_mh = assembly_idhs.first.createMH()
        ndx_module_branches = Hash.new
        get_objs(assembly_mh,sp_hash).each do |r|
          module_branch = r[:module_branch]
          assembly_name = r[:display_name]
          assembly_dir = assembly_meta_directory_path(assembly_name)
          RepoManager.delete_directory?(assembly_dir,module_branch)
          ndx_module_branches[module_branch[:id]] ||= module_branch
        end
        ndx_module_branches.each_value do |module_branch|
          RepoManager.push_changes(module_branch)
        end
      end

      def update_model_from_dsl(container_idh,module_branch,module_name)
        update_global_refs(module_branch)
        update_assemblies_from_dsl(container_idh,module_branch,module_name)
      end

      def assembly_meta_directory_path(assembly_name)
        "assemblies/#{assembly_name}"
      end
      def assembly_meta_filename_path(assembly_name)
        "#{assembly_meta_directory_path(assembly_name)}/assembly.json"
      end
      def assembly_dsl_filename_path_info()
        {
          :regexp => Regexp.new("assembly.json$"),
          :path_depth => 3
        }
      end

     private
      def update_assemblies_from_dsl(container_idh,module_branch,module_name)
        module_branch_idh = module_branch.id_handle()
        assembly_dsl_path_info = assembly_dsl_filename_path_info()
        add_on_dsl_path_info = ServiceAddOn.dsl_filename_path_info()
        depth = [assembly_dsl_path_info[:path_depth],add_on_dsl_path_info[:path_depth]].max
        files = RepoManager.ls_r(depth,{:file_only => true},module_branch)
        
        assembly_import_helper = AssemblyImport.new(container_idh,module_name)
        files.select{|f|f =~ assembly_dsl_path_info[:regexp]}.each do |meta_file|
          json_content = RepoManager.get_file_content(meta_file,module_branch)
          hash_content = JSON.parse(json_content)
          assemblies_hash = hash_content["assemblies"].values.inject(Hash.new) do |h,assembly_info|
            h.merge(assembly_ref(module_name,assembly_info["name"]) => assembly_info)
          end
          node_bindings_hash = hash_content["node_bindings"]
          assembly_import_helper.add_assemblies(module_branch_idh,assemblies_hash,node_bindings_hash)
        end
        assembly_import_helper.import()
        ports = assembly_import_helper.ports()
        aug_assembly_nodes = assembly_import_helper.augmented_assembly_nodes()
        files.select{|f| f =~ add_on_dsl_path_info[:regexp]}.each do |meta_file|
          json_content = RepoManager.get_file_content({:path => meta_file},module_branch)
          hash_content = JSON.parse(json_content)
          ServiceAddOn.import(container_idh,module_name,meta_file,hash_content,ports,aug_assembly_nodes)
        end
      end

      def update_global_refs(module_branch)
        json_content = RepoManager.get_file_content(GlobalModuleRefs.meta_filename_path(),module_branch)
        constraints_hash_form = JSON.parse(json_content)
        vconstraints = module_branch.get_module_version_constraints()
        vconstraints.set_and_save_constraints!(constraints_hash_form)
      end
    end
  end
end


