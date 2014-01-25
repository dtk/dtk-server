#TODO: move to more descriptive includes
module DTK; class ComponentModule
  module ManagementMixin
    def delete_object()
      assembly_templates = get_associated_assembly_templates()
      unless assembly_templates.empty?
        assembly_names = assembly_templates.map{|a|a.display_name_print_form()}
        raise ErrorUsage.new("Cannot delete the component module because the assembly template(s) (#{assembly_names.join(',')}) reference it")
      end

      components = get_associated_component_instances()
      unless components.empty?
        ndx_assemblies = Hash.new
        asssembly_ids =  components.map{|r|r[:assembly_id]}.compact
        unless asssembly_ids.empty?
          sp_hash = {
            :cols => [:id,:group_id,:display_name],
            :filter => [:oneof,:id,asssembly_ids]
          }
          ndx_assemblies = Assembly::Instance.get_objs(model_handle(:assembly_instance),sp_hash).inject(Hash.new){|h,r|h.merge(r[:id] => r)}
        end
        component_names = components.map do |r|
          cmp_name = r.display_name_print_form(:node_prefix=>true)
          if assembly = ndx_assemblies[r[:assembly_id]]
            cmp_name = "#{assembly.display_name_print_form()}/#{cmp_name}"
          end
          cmp_name
        end
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

    def delete_version?(version)
      delete_version(version,:no_error_if_does_not_exist=>true)
    end
    def delete_version(version,opts={})
      ret = {:module_name => module_name()}
      unless module_branch = get_module_branch_matching_version(version)
        if opts[:no_error_if_does_not_exist]
          return ret
        else
          raise ErrorUsage.new("Version '#{version}' for specified component module does not exist") 
        end
      end

      if implementation = module_branch.get_implementation()
        delete_instance(implementation.id_handle())
      end
      module_branch.delete_instance_and_repo_branch()
      ret
    end


   private
    def create_new_version__type_specific(repo_for_new_branch,new_version,opts={})
      create_needed_objects_and_dsl?(repo_for_new_branch,new_version,opts)
    end

    def update_model_from_clone__type_specific?(commit_sha,diffs_summary,module_branch,version,opts={})
      update_model_objs_or_create_dsl?(diffs_summary,module_branch,version,opts)
    end

  end              
end; end
