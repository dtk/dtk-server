module DTK; class AssemblyModule
  class TestModule < self
    r8_nested_require('component','ad_hoc_link')
    r8_nested_require('component','attribute')

    def self.prepare_for_edit(assembly,component_module)
      new(assembly).prepare_for_edit(component_module)
    end
    def prepare_for_edit(component_module)
      get_applicable_component_instances(component_module,:raise_error_if_empty => true)
      create_assembly_branch?(component_module)
    end

    def self.finalize_edit(assembly,component_module,module_branch)
      new(assembly).finalize_edit(component_module,module_branch)
    end
    def finalize_edit(component_module,module_branch)
      modify_cmp_instances_with_new_parents(component_module,module_branch)
    end

    def delete_modules?()
      am_version = assembly_module_version()
      # do not want to use assembly.get_component_modules() to generate component_modules because there can be modules taht do not correspond to component instances
      sp_hash = {
        :cols => [:id,:group_id,:display_name,:component_id],
        :filter => [:eq,:version,am_version]
      }
      component_module_mh = @assembly.model_handle(:test_module)
      Model.get_objs(@assembly.model_handle(:module_branch),sp_hash).each do |r|
        unless r[:test_id]
          Log.error("Unexpected that #{r.inspect} has :component_id nil; workaround is to delete this module branch")
          Model.delete_instance(r.id_handle())
          next
        end
        component_module = component_module_mh.createIDH(:id => r[:test_id]).create_object()
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

   private
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
      opts = {:base_version=>component_module.get_field?(:version),:assembly_module=>true}
      # TODO: very expensive call; will refine
      component_module.create_new_version(am_version,opts)
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
      ndx_workspace_branches = TestModule.get_workspace_module_branches(mod_idhs).inject(Hash.new) do |h,r|
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
        r[:local_copy_diff]  = (assembly_mod_sha != workspace_mod_sha)
=begin
<<<<<<< HEAD
TODO: code to put in when
want to check case when :local_behind and :branchpoint
In order to do this must ireate all branches, not just changed ones and
need to do a refresh on workspace branch sha in case this was updated in another branch
=======
TODO: code to put in when 
want to check case when :local_behind and :branchpoint
In order to do this must ireate all branches, not just changed ones and
need to do a refresh on workspace branch sha in case this was updated in another branch 
>>>>>>> 96c2c04aa30222959aa0072999573db7a55327d0
        if r[:local_copy_diff]
          sha_relationship = RepoManager.ret_sha_relationship(assembly_mod_sha,workspace_mod_sha,assembly_mod_branch)
          case sha_relationship
            when :local_behind,:local_ahead,:branchpoint
              r[:branch_relationship] = sha_relationship
            when :equal
              # unequal shas but equal content
              # TODO: is it possible to reach this
              r[:local_copy_diff]  = false
          end
        end
=end
      end
      modules_with_branches
    end

    def modify_cmp_instances_with_new_parents(component_module,module_branch)
      cmp_instances = get_applicable_component_instances(component_module)
      update_impacted_component_instances(cmp_instances,module_branch,component_module.get_project().id_handle())
    end

    def update_impacted_component_instances(cmp_instances,module_branch,project_idh)
      module_branch_id = module_branch[:id]

      # shortcut; do not need to update components that are set already to this module id; and for added protection making
      # sure that these it does not have :locked_sha set
      cmp_instances_needing_update = cmp_instances.reject do |cmp|
        (cmp.get_field?(:module_branch_id) == module_branch_id) and
          ((cmp.has_key?(:locked_sha) and cmp[:locked_sha].nil?) or cmp.get_field?(:locked_sha).nil?)
      end
      return if cmp_instances_needing_update.empty?
      component_types = cmp_instances_needing_update.map{|cmp|cmp.get_field?(:component_type)}.uniq
      version_field = module_branch.get_field?(:version)
      type_version_field_list = component_types.map{|ct|{:component_type => ct, :version_field => version_field}}
      ndx_cmp_templates = DTK::Component::Template.get_matching_type_and_version(project_idh,type_version_field_list).inject(Hash.new) do |h,r|
        h.merge(r[:component_type] => r)
      end
      rows_to_update = cmp_instances_needing_update.map do |cmp|
        if cmp_template = ndx_cmp_templates[cmp[:component_type]]
          {
            :id => cmp[:id],
            :module_branch_id => module_branch_id,
            :version => cmp_template[:version],
            :locked_sha => nil, #this servers to let component instance get updated as this branch is updated
            :implementation_id => cmp_template[:implementation_id],
            :ancestor_id => cmp_template[:id]
          }
        else
          Log.error("Cannot find matching component template for component instance (#{cmp.inspect}) for version (#{version_field})")
          nil
        end
      end.compact
      unless rows_to_update.empty?
        Model.update_from_rows(project_idh.createMH(:component),rows_to_update)
      end
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
