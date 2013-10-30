module DTK; class AssemblyModule
  class Component
    class Attribute < self
      def self.update(assembly,cmp_level_attr_patterns)
        #TODO: more efficient to bulk up cmp_level_attr_patterns
        cmp_level_attr_patterns.map{|ap|update_aux(assembly,ap)}
      end

     private
      def self.update_aux(assembly,cmp_level_attr_pattern)
        cmp_template = cmp_level_attr_pattern.component_instance().get_component_template_parent()
        component_module = cmp_template.get_component_module()
        module_branch = create_assembly_branch?(assembly,component_module,:ret_module_branch=>true)
        branch_cmp_template = get_branch_template(module_branch,cmp_template)
        new_cmp_template_attr_idh = cmp_level_attr_pattern.create_attribute_on_template(branch_cmp_template)
        pp ["in #{self}, next step is to update dsl"]
      end
    end
  end
end;end

