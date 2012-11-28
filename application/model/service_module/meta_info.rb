module DTK
  class ServiceModule
    module MetaInfoClassMixin
      def delete_assembly_meta_info?(assembly_idh)
        assembly = assembly_idh.create_object().get_obj(:cols => [:display_name, :module_branch])
        module_branch = assembly[:module_branch]
        assembly_name = assembly[:display_name]
        assembly_dir = assembly_meta_directory_path(assembly_name)
        RepoManager.delete_directory?(assembly_dir,{:push_changes => true},module_branch)
      end

      def create_assembly_meta_info?(library_idh,module_branch,module_name)
        module_branch_idh = module_branch.id_handle()
        assembly_meta_info = assembly_meta_filename_path_info()
        add_on_meta_info = ServiceAddOn.meta_filename_path_info()
        depth = [assembly_meta_info[:path_depth],add_on_meta_info[:path_depth]].max
        files = RepoManager.ls_r(depth,{:file_only => true},module_branch)
        
        ndx_ports = Hash.new
        files.select{|f|f =~ assembly_meta_info[:regexp]}.each do |meta_file|
          json_content = RepoManager.get_file_content({:path => meta_file},module_branch)
          hash_content = JSON.parse(json_content)
          assemblies_hash = hash_content["assemblies"].values.inject(Hash.new) do |h,assembly_info|
            h.merge(assembly_ref(module_name,assembly_info["name"]) => assembly_info)
          end
          node_bindings_hash = hash_content["node_bindings"]
          import_info = Assembly.import(library_idh,module_branch_idh,module_name,assemblies_hash,node_bindings_hash)
          if import_info[:ndx_ports]
            ndx_ports.merge!(import_info[:ndx_ports])
          end
        end
        files.select{|f| f =~ add_on_meta_info[:regexp]}.each do |meta_file|
          json_content = RepoManager.get_file_content({:path => meta_file},module_branch)
          hash_content = JSON.parse(json_content)
          ports = ndx_ports.values
          ServiceAddOn.import(library_idh,module_name,meta_file,hash_content,ports)
        end
      end
      
      def assembly_meta_directory_path(assembly_name)
        "assemblies/#{assembly_name}"
      end
      def assembly_meta_filename_path(assembly_name)
        "#{assembly_meta_directory_path(assembly_name)}/assembly.json"
      end
      def assembly_meta_filename_path_info()
        {
          :regexp => Regexp.new("assembly.json$"),
          :path_depth => 3
        }
      end
    end
  end
end


