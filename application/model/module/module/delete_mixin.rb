module DTK; class BaseModule
  module DeleteMixin
    def delete_object
      assembly_templates = get_associated_assembly_templates()
      unless assembly_templates.empty?
        assembly_names = assembly_templates.map{|a|a.display_name_print_form(include_namespace: true)}
        raise ErrorUsage.new("Cannot delete the component module because the assembly template(s) (#{assembly_names.join(',')}) reference it")
      end

      components = get_associated_component_instances()
      raise_error_component_refs(components) unless components.empty?

      impls = get_implementations()
      delete_instances(impls.map(&:id_handle))
      repos = get_repos()
      repos.each{|repo|RepoManager.delete_repo(repo)}
      delete_instances(repos.map(&:id_handle))
      delete_instance(id_handle())
      {module_name: module_name()}
    end

    def delete_version?(version)
      delete_version(version,no_error_if_does_not_exist: true)
    end

    def delete_version(version,opts={})
      ret = {module_name: module_name()}
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

    def raise_error_component_refs(components)
      ndx_assemblies = {}
      asssembly_ids =  components.map{|r|r[:assembly_id]}.compact
      unless asssembly_ids.empty?
        sp_hash = {
          cols: [:id,:group_id,:display_name],
          filter: [:oneof,:id,asssembly_ids]
        }
        ndx_assemblies = Assembly::Instance.get_objs(model_handle(:assembly_instance),sp_hash).inject({}){|h,r|h.merge(r[:id] => r)}
      end
      refs = components.map do |r|
        cmp_ref = r.display_name_print_form(node_prefix: true,namespace_prefix: true)
        ref =
          if cmp_ref =~ /(^[^\/]+)\/([^\/]+$)/
            "Reference to '#{$2}' on node '#{$1}'"
          else
            "Reference to '#{cmp_ref}'"
          end
        if assembly = ndx_assemblies[r[:assembly_id]]
          ref << " in service instance '#{assembly.display_name_print_form()}'"
        end
        ref
      end
      raise ErrorUsage.new("Cannot delete the component module because the following:\n  #{refs.join("\n  ")}")    end
  end
end; end
