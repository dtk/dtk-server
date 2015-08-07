module DTK; class AssemblyModule
  class Component
    class Get < self
      module Mixin
        def get_branch_template(module_branch, cmp_template)
          sp_hash = {
            cols: [:id, :group_id, :display_name, :component_type],
            filter: [:and, [:eq, :module_branch_id, module_branch.id()],
                     [:eq, :type, 'template'],
                     [:eq, :node_node_id, nil],
                     [:eq, :component_type, cmp_template.get_field?(:component_type)]]
          }
          Model.get_obj(cmp_template.model_handle(), sp_hash) || fail(Error.new('Unexpected that branch_cmp_template is nil'))
        end
            
        def get_applicable_component_instances(component_module)
          assembly_id = @assembly.id()
          component_module.get_associated_component_instances().select do |cmp|
            cmp[:assembly_id] == assembly_id
          end
        end
      end

      module ClassMixin
        def get_for_assembly(assembly, mode, opts = {})
          Get.new(assembly).get_for_assembly(mode, opts)
        end
        
        # returns namespace if module_name exists in assembly
        def get_namespace?(assembly, module_name)
          Namespace.namespace?(module_name) || ModuleRefs::Lock.get_namespace?(assembly, module_name)
        end

        # returns [namespace, locked_branch_sha] if module_name exists in assembly
        # namespace can at the same time that locked_branch_sha may be nil
        def get_namespace_and_locked_branch_sha?(assembly, module_name)
          locked_branch_sha = nil
          if namespace = Namespace.namespace?(module_name)
            locked_branch_sha = ModuleRefs::Lock.get_locked_branch_sha?(assembly, module_name)
          else
            namespace, locked_branch_sha = ModuleRefs::Lock.get_namespace_and_locked_branch_sha?(assembly, module_name)
          end
          [namespace, locked_branch_sha]
        end
      end

      # opts can have keys
      #  :get_branch_relationship_info - Boolean
      #
      # mode is one of 
      # :direct - only component modules directly included
      # :recursive - directly connected and nested component modules 
      def get_for_assembly(mode, opts = {})
        ret =
          case mode
            when :direct    then get_with_branches__direct(opts)
            when :recursive then get_with_branches__recursive
            else fail Error.new("Illegal mode '#{mode}'")
          end
        if opts[:get_branch_relationship_info]
          add_branch_relationship_info!(ret)
        end
        # remove branches since they are no longer needed
        ret.each { |r| r.delete(:module_branch) }
        ret
      end

      private

      # Finds, not just directly referenced component modules, but the recursive closure 
      # taking into account all locked component module refs
      def get_with_branches__recursive
        ret = []
        locked_module_refs = ModuleRefs::Lock.get_all(@assembly, with_module_branches: true, types: [:locked_dependencies])
        # get component modules by finding the component module id in locked_module_refs elements
        els_ndx_by_cmp_mod_ids = {}
        locked_module_refs.elements.each do |el|
          if component_id = (el.module_branch || {})[:component_id]
            els_ndx_by_cmp_mod_ids[component_id] =  el
          end
        end
        return ret if els_ndx_by_cmp_mod_ids.empty?

        sp_hash = {
          cols: [:id, :display_name, :group_id, :namespace_id],
          filter: [:oneof, :id, els_ndx_by_cmp_mod_ids.keys]
        }
        ret = Model.get_objs(@assembly.model_handle(:component_module), sp_hash)
        ret.each do |r|
          if el = els_ndx_by_cmp_mod_ids[r[:id]]
            to_add = {
              namespace_name: el.namespace,
              dsl_parsed: (el.module_branch || {})[:dsl_parsed],
              module_branch: el.module_branch
            }
            r.merge!(to_add)
          end
        end
        ret
      end

      def get_with_branches__direct(opts = {})
        add_module_branches = opts[:get_branch_relationship_info]
        # there is a row for each component; assumption is that all rows belonging to same component wil match on all info
        # being collected; so pruning out duplicates for same component_module
        ndx_ret = {}
        @assembly.get_objs(cols: [:instance_component_module_branches]).each do |r|
          component_module = r[:component_module]
          ndx = component_module.id
          next if ndx_ret[ndx]

          if namespace = (r[:namespace] || {})[:display_name]
            component_module.merge!(namespace_name: namespace)
          end
          if dsl_parsed = (r[:module_branch] || {})[:dsl_parsed]
            component_module.merge!(dsl_parsed: dsl_parsed)
          end
          if add_module_branches
            component_module.merge!(r.hash_subset(:module_branch))
          end
          
          ndx_ret[ndx] = component_module
        end
        ndx_ret.values
      end

      # TODO: if this is derived from ModuleRefs::Lock can do this more efficienctly by having ModuleRefs::Lock have base branch
      def add_branch_relationship_info!(modules_with_branches)
        local_copy_els = []
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
        mod_idhs = local_copy_els.map(&:id_handle)
        ndx_workspace_branches = ComponentModule.get_workspace_module_branches(mod_idhs).inject({}) do |h, r|
          h.merge(r[:module_id] => r)
        end

        local_copy_els.each do |r|
          unless workspace_branch = ndx_workspace_branches[r[:id]]
            Log.error('Unexpected that ndx_workspace_branches[r[:id]] is null')
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
            Log.error('Unexpected that workspace_mod_sha is nil')
          end
          r[:local_copy_diff] = (assembly_mod_sha != workspace_mod_sha)
          # TODO: code to put in when
          # want to check case when :local_behind and :branchpoint
          # In order to do this must ireate all branches, not just changed ones and
          # need to do a refresh on workspace branch sha in case this was updated in another branch
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
end; end
