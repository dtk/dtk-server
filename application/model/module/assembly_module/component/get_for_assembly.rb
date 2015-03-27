module DTK; class AssemblyModule
  class Component
    class GetForAssembly < self
      def get_for_assembly(opts={})
        add_module_branches = opts[:get_version_info]
        ret = (opts[:recursive] ? get_with_branches_recursive(opts) : get_with_branches(opts))
        
        add_version_info!(ret) if add_module_branches

        # remove branches; they are no longer needed
        ret.each{|r|r.delete(:module_branch)}
        ret
      end

     private
      # Finds, not just dircctly referenced component modules, but the recursive clouse taking into account all locked component module refs
      def get_with_branches_recursive(opts={})
        ret = Array.new
        locked_module_refs = ModuleRefs::Lock.get(@assembly,:types => [:elements]).add_matching_module_branches!()
        # get component modules by finding the component module id in locked_module_refs elements
        els_ndx_by_cmp_mod_ids = Hash.new
        locked_module_refs.elements.each do |el|
          if component_id = (el.module_branch||{})[:component_id]
            els_ndx_by_cmp_mod_ids[component_id] =  el
          end
        end
        return ret if els_ndx_by_cmp_mod_ids.empty?
        
        sp_hash = {
          :cols => [:id,:display_name,:group_id,:namespace_id],
          :filter => [:oneof,:id, els_ndx_by_cmp_mod_ids.keys]
        }
        ret = Model.get_objs(@assembly.model_handle(:component_module),sp_hash)
        ret.each do |r|
          if el = els_ndx_by_cmp_mod_ids[r[:id]]
            to_add = {
              :namespace_name => el.namespace, 
              :dsl_parsed     => (el.module_branch||{})[:dsl_parsed],
              :module_branch  => el.module_branch
            }
            r.merge!(to_add)
          end
        end
        ret
      end
      # TODO: make sure that where these two overlap they are consistent in namespace assignments
      def get_with_branches(opts={})
        ndx_ret = Hash.new
        add_module_branches = opts[:get_version_info]
        # there is a row for each component; assumption is that all rows belonging to same component with have same branch
        @assembly.get_objs(:cols=> [:instance_component_module_branches]).each do |r|
          component_module = r[:component_module]
          component_module.merge!({:namespace_name => r[:namespace][:display_name]}) if r[:namespace]
          component_module.merge!({:dsl_parsed => r[:module_branch][:dsl_parsed]}) if r[:module_branch]
          ndx_ret[component_module[:id]] ||= component_module.merge(add_module_branches ? r.hash_subset(:module_branch) : {})
        end
        ndx_ret.values
      end

      # TODO: is this is derived from ModuleRefs::Lock can do this more efficienctly by having ModuleRefs::Lock have base branch
      def add_version_info!(modules_with_branches)
        local_copy_els = Array.new
        modules_with_branches.each do |r|
          if r[:module_branch].assembly_module_version?()
            r[:local_copy] = true
            local_copy_els << r
          end
        end
        
      # for each item with local_copy, check for diff_from_base
        if local_copy_els.empty?
          return modules_with_branches
        end
        # TODO: check if we are missing anything; maybe when there is just a meta change we dont update what component pointing to
        # but create a new branch, which we can check with ComponentModule.get_workspace_module_branches with idhs from all els in modules_with_branches
        # this is related to DTK-1214
        
        # get the associated master branch and see if there is any diff
        mod_idhs = local_copy_els.map{|r|r.id_handle()}
        ndx_workspace_branches = ComponentModule.get_workspace_module_branches(mod_idhs).inject(Hash.new) do |h,r|
          h.merge(r[:module_id] => r)
        end
        
        local_copy_els.each do |r|
          unless workspace_branch = ndx_workspace_branches[r[:id]]
            Log.error("Unexpected that ndx_workspace_branches[r[:id]] is null")
            next
          end
          assembly_mod_branch = r[:module_branch]
          unless assembly_mod_sha = assembly_mod_branch[:current_sha]
            # This can happend if user goes into edit mode, but makes no changes o a component module
            # r.delete(:local_copy) is so it does not appear as editted
            r.delete(:local_copy)
            next
          end
          unless workspace_mod_sha = workspace_branch[:current_sha]
            Log.error("Unexpected that workspace_mod_sha is nil")
          end
          r[:local_copy_diff] = (assembly_mod_sha != workspace_mod_sha)
=begin
TODO: code to put in when
want to check case when :local_behind and :branchpoint
In order to do this must ireate all branches, not just changed ones and
need to do a refresh on workspace branch sha in case this was updated in another branch
=end
          if r[:local_copy_diff]
            sha_relationship = RepoManager.ret_sha_relationship(assembly_mod_sha, workspace_mod_sha, assembly_mod_branch)
            case sha_relationship
            when :local_behind, :local_ahead, :branchpoint
              r[:branch_relationship] = sha_relationship
            when :equal
              r[:local_copy_diff]  = false
            end
          end
        end

        modules_with_branches
      end

    end
  end
end;end

