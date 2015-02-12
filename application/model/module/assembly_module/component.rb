module DTK; class AssemblyModule
  class Component < self
    r8_nested_require('component','ad_hoc_link')
    r8_nested_require('component','attribute')

    def self.prepare_for_edit(assembly,component_module)
      new(assembly).prepare_for_edit(component_module)
    end
    def prepare_for_edit(component_module)
      get_applicable_component_instances(component_module,:raise_error_if_empty => true)
      create_assembly_branch?(component_module)
    end

    def self.finalize_edit(assembly,component_module,module_branch,opts={})
      new(assembly).finalize_edit(component_module,module_branch,opts)
    end
    def finalize_edit(component_module,module_branch,opts={})
      cmp_instances = get_applicable_component_instances(component_module)
      project_idh = component_module.get_project().id_handle()
      Clone::IncrementalUpdate::Component.new(project_idh,module_branch).update?(cmp_instances,opts)
    end

    def delete_modules?()
      am_version = assembly_module_version()
      # do not want to use assembly.get_component_modules() to generate component_modules because there can be modules taht do not correspond to component instances
      sp_hash = {
        :cols => [:id,:group_id,:display_name,:component_id],
        :filter => [:eq,:version,am_version]
      }
      component_module_mh = @assembly.model_handle(:component_module)
      Model.get_objs(@assembly.model_handle(:module_branch),sp_hash).each do |r|
        unless r[:component_id]
#          Log.error("Unexpected that #{r.inspect} has :component_id nil; workaround is to delete this module branch")
          Model.delete_instance(r.id_handle())
          next
        end
        component_module = component_module_mh.createIDH(:id => r[:component_id]).create_object()
        component_module.delete_version?(am_version)
      end
    end

    def self.create_component_dependency?(type,assembly,cmp_template,antecedent_cmp_template,opts={})
      AdHocLink.new(assembly).create_dependency?(type,cmp_template,antecedent_cmp_template,opts)
    end

    def self.promote_module_updates(assembly,component_module,opts={})
      new(assembly).promote_module_updates(component_module,opts)
    end
    def promote_module_updates(component_module,opts={})
      am_version = assembly_module_version()
      unless branch = component_module.get_workspace_module_branch(am_version)
        component_module_id = component_module.id()
        if @assembly.get_component_modules().find{|r|r[:id] == component_module_id}
          raise ErrorNoChangesToModule.new(@assembly,component_module)
        else
          raise ErrorNoComponentsInModule.new(@assembly,component_module)
        end
      end
      unless ancestor_branch = branch.get_ancestor_branch?()
        raise Error.new("Cannot find ancestor branch")
      end
      branch_name = branch[:branch]
      ancestor_branch.merge_changes_and_update_model?(component_module,branch_name,opts)
    end

    def self.get_for_assembly(assembly,opts={})
      new(assembly).get_for_assembly(opts)
    end
    def get_for_assembly(opts={})
      ndx_ret = Hash.new
      add_module_branches = opts[:get_version_info]
      # there is a row for each component; assumption is that all rows belonging to same component with have same branch
      @assembly.get_objs(:cols=> [:instance_component_module_branches]).each do |r|
        component_module = r[:component_module]
        component_module.merge!({:namespace_name => r[:namespace][:display_name]}) if r[:namespace]
        component_module.merge!({:dsl_parsed => r[:module_branch][:dsl_parsed]}) if r[:module_branch]
        ndx_ret[component_module[:id]] ||= component_module.merge(add_module_branches ? r.hash_subset(:module_branch) : {})
      end
      ret = ndx_ret.values
      if add_module_branches
        add_version_info!(ret)
      end

      # remove branches; they are no longer needed
      ret.each{|r|r.delete(:module_branch)}

      ret
    end

    def self.validate_component_module_ret_namespace(assembly,module_name)
      new(assembly).validate_component_module_ret_namespace(module_name)
    end
    def validate_component_module_ret_namespace(module_name)
      namespace, name = Namespace.full_module_name_parts?(module_name)
      return namespace if namespace

      component_modules = get_for_assembly()
      matching_by_name = component_modules.select{|cm| cm[:display_name].eql?(module_name)}

      raise ErrorUsage.new("No object of type component module with name (#{module_name}) exists") if matching_by_name.empty?
      raise ErrorUsage.new("Multiple components modules matching name you provided. Please use namespace::component_module format!") if matching_by_name.size > 1

      namespace = matching_by_name.first[:namespace_name] if matching_by_name.size == 1
      namespace
    end

    def self.list_remote_diffs(model_handle, module_id, repo, module_branch, workspace_branch, opts)
      diffs, diff = [], nil
      remote_repo_cols = [:id, :display_name, :version, :remote_repos, :dsl_parsed]
      project_idh      = opts[:project_idh]

      sp_hash = {
        :cols => [:id, :group_id, :display_name, :component_type],
        :filter => [:and,
                    [:eq, :type, 'component_module'],
                    [:eq, :version, ModuelBranch.version_field_default()],
                    [:eq, :repo_id, repo.id()],
                    [:eq, :component_id, module_id]
                   ]
      }
      base_branch = Model.get_obj(module_branch.model_handle(), sp_hash)
      diff = repo.get_local_branches_diffs(module_branch, base_branch, workspace_branch)

      diff.each do |diff_obj|
        path = "diff --git a/#{diff_obj.a_path} b/#{diff_obj.b_path}\n"
        diffs << (path + "#{diff_obj.diff}\n")
      end

      diffs
    end

   private
    def get_for_assembly__augment_name_with_namespace!(cmp_modules)
      return if cmp_modules.empty?
      ndx_cmp_modules = cmp_modules.inject(Hash.new){|h,m|h.merge(m[:id] => m)}
      ComponentModule.ndx_full_module_names(cmp_modules.map{|m|m.id_handle()}).each_pair do |ndx,full_module_name|
        ndx_cmp_modules[ndx][:display_name] = full_module_name
      end
    end

    def create_assembly_branch?(component_module,opts={})
      am_version = assembly_module_version()
      unless component_module.get_workspace_module_branch(am_version)
        create_assembly_branch(component_module,am_version)
      end
      ret = component_module.get_workspace_branch_info(am_version)
      if opts[:ret_module_branch]
        ret[:module_branch_idh].create_object()
      else
        ret
      end
    end

    def create_assembly_branch(component_module,am_version)
      base_version = component_module.get_field?(:version) #TODO: is this right; shouldnt version be on branch, not module
      component_module.create_new_version(base_version,am_version)
    end

    def get_branch_template(module_branch,cmp_template)
      sp_hash = {
        :cols => [:id,:group_id,:display_name,:component_type],
        :filter => [:and,[:eq,:module_branch_id,module_branch.id()],
                    [:eq,:type,'template'],
                    [:eq,:node_node_id,nil],
                    [:eq,:component_type,cmp_template.get_field?(:component_type)]]
      }
      Model.get_obj(cmp_template.model_handle(),sp_hash) || raise(Error.new("Unexpected that branch_cmp_template is nil"))
    end

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
          Log.error("Unexpected that ndx_workspace_branchesr[r[:id]] is null")
          next
        end
        assembly_mod_branch = r[:module_branch]
        unless assembly_mod_sha = assembly_mod_branch[:current_sha]
          Log.error("Unexpected that assembly_mod_sh is nil")
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

    def get_applicable_component_instances(component_module,opts={})
      assembly_id = @assembly.id()
      ret = component_module.get_associated_component_instances().select do |cmp|
        cmp[:assembly_id] == assembly_id
      end
      if opts[:raise_error_if_empty] and ret.empty?()
        raise ErrorNoComponentsInModule.new(@assembly,component_module)
      end
      ret
    end

    class ErrorComponentModule < ErrorUsage
      def initialize(assembly,component_module)
        @assembly_name = assembly.display_name_print_form()
        @module_name = component_module.get_field?(:display_name)
        super(error_msg())
      end
    end
    class ErrorNoChangesToModule < ErrorComponentModule
     private
      def error_msg()
        "Changes to component module (#{@module_name}) have not been made in assembly (#{@assembly_name})"
      end
    end
    class ErrorNoComponentsInModule < ErrorComponentModule
      private
      def error_msg()
        "Assembly (#{@assembly_name}) does not have any components belonging to module (#{@module_name})"
      end
    end
  end
end; end

