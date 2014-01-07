module DTK; class AssemblyModule
  class Component < self
    r8_nested_require('component','ad_hoc_link')
    r8_nested_require('component','attribute')

    def self.prepare_for_edit(assembly,component_module)
      get_applicable_component_instances(assembly,component_module,:raise_error_if_empty => true)
      create_assembly_branch?(assembly,component_module)
    end

    def self.finalize_edit(assembly,component_module,module_branch)
      modify_cmp_instances_with_new_parents(assembly,component_module,module_branch)
    end

    def self.create_component_dependency?(type,assembly,cmp_template,antecedent_cmp_template,opts={})
      AdHocLink.create_dependency?(type,assembly,cmp_template,antecedent_cmp_template,opts)
    end

    def self.promote_module_updates(assembly,component_module,opts={})
      module_version = ModuleVersion.ret(assembly)
      unless branch = component_module.get_workspace_module_branch(module_version)
        component_module_name = 
        component_module_id = component_module.id()
        if assembly.get_component_modules().find{|r|r[:id] == component_module_id}
          raise ErrorNoChangesToModule.new(assembly,component_module)
        else
          raise ErrorNoComponentsInModule.new(assembly,component_module)
        end
      end
      unless ancestor_branch = branch.get_ancestor_branch?()
        raise Error.new("Cannot find ancestor branch")
      end
      branch_name = branch[:branch]
      ancestor_branch.merge_changes_and_update_model?(component_module,branch_name,opts)
    end

   private
    def self.create_assembly_branch?(assembly,component_module,opts={})
      module_version = ModuleVersion.ret(assembly)
      unless component_module.get_workspace_module_branch(module_version)
        create_assembly_branch(component_module,module_version)
      end
      ret = component_module.get_workspace_branch_info(module_version)
      if opts[:ret_module_branch]
        ret[:module_branch_idh].create_object()
      else
        ret
      end
    end

    def self.create_assembly_branch(component_module,module_version)
      opts = {:base_version=>component_module.get_field?(:version),:assembly_module=>true}
      #TODO: very expensive call; will refine
      component_module.create_new_version(module_version,opts)
    end

    def self.get_branch_template(module_branch,cmp_template)
      sp_hash = {
        :cols => [:id,:group_id,:display_name,:component_type],
        :filter => [:and,[:eq,:module_branch_id,module_branch.id()],
                    [:eq,:type,'template'],
                    [:eq,:node_node_id,nil],
                    [:eq,:component_type,cmp_template.get_field?(:component_type)]]
      }
      Model.get_obj(cmp_template.model_handle(),sp_hash) || raise(Error.new("Unexpected that branch_cmp_template is nil"))
    end
    
    def self.delete_modules?(assembly)
      module_version = ModuleVersion.ret(assembly)
      #do not want to use assembly.get_component_modules() to generate component_modules because there can be modules taht do not correspond to component instances
      sp_hash = {
        :cols => [:id,:group_id,:display_name,:component_id],
        :filter => [:eq,:version,module_version]
      }
      component_module_mh = assembly.model_handle(:component_module)
      Model.get_objs(assembly.model_handle(:module_branch),sp_hash).each do |r|
        unless r[:component_id]
          Log.error("Unexpected that #{r.inspect} has :component_id nil; workaround is to delete this module branch")
          Model.delete_instance(r.id_handle())
          next
        end
        component_module = component_module_mh.createIDH(:id => r[:component_id]).create_object()
        component_module.delete_version?(module_version)
      end
    end

    def self.modify_cmp_instances_with_new_parents(assembly,component_module,module_branch)
      cmp_instances = get_applicable_component_instances(assembly,component_module)
      update_impacted_component_instances(cmp_instances,module_branch,component_module.get_project().id_handle())
    end

    def self.update_impacted_component_instances(cmp_instances,module_branch,project_idh)
      module_branch_id = module_branch[:id]

      #shortcut; do not need to update components that are set already to this module id; and for added protection making
      #sure that these it does not have :locked_sha set
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

    def self.get_applicable_component_instances(assembly,component_module,opts={})
      assembly_id = assembly.id()
      ret = component_module.get_associated_component_instances().select do |cmp|
        cmp[:assembly_id] == assembly_id
      end
      if opts[:raise_error_if_empty] and ret.empty?()
        raise ErrorNoComponentsInModule.new(assembly,component_module)
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
        "There are no changes to component module (#{@module_name}) in assembly (#{@assembly_name}) to push"
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

