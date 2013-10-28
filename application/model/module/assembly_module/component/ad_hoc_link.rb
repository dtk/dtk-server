module DTK; class AssemblyModule
  class Component
    class AdHocLink < self
      def initialize(assembly,parsed_adhoc_link)
        @assembly = assembly
        @source_attr_pattern = parsed_adhoc_link.attribute_pattern(:source)
        @target_attr_pattern = parsed_adhoc_link.attribute_pattern(:target)
      end

      def update_assembly_module(opts={})
        #determine which is the dependent component and which is the antec one 
        dep_cmp,antec_cmp = determine_dep_and_antec_components(opts)
        dep_cmp_template = dep_cmp.get_component_template_parent()
        antec_cmp_template = antec_cmp.get_component_template_parent()

        component_module = dep_cmp_template.get_component_module()
        module_branch = self.class.create_assembly_branch?(@assembly,component_module,:ret_module_branch=>true)

        opts_create_dep = {
          :antec_attr_pattern => @source_attr_pattern,
          :dep_attr_pattern => @target_attr_pattern,
          :update_dsl => true
        }
        result = Dependency.create_dependency?(:link,@assembly,dep_cmp_template,antec_cmp_template,module_branch,opts_create_dep)
        if result[:component_module_updated]
          self.class.modify_cmp_instances_with_new_parents(@assembly,component_module,module_branch)
        end
        result.merge(:dep_component => dep_cmp, :antec_component => antec_cmp) 
      end

     private
      def determine_dep_and_antec_components(opts={})
        unless target_cmp = @target_attr_pattern.component_instance()
          raise Error.new("Unexpected that target_attr_pattern.component() is nil")
        end
        #source_cmp can be nil when link to a node attribute
        source_cmp = @source_attr_pattern.component_instance()
        unless source_cmp
          raise Error.new("Not implemented yet when source_cmp is nil")
        end
        #TODO: stub heuristic that chooses target_cmp as dependent
        dep_cmp = target_cmp
        antec_cmp = source_cmp
        [dep_cmp,antec_cmp]
      end
    end
  end
end;end
