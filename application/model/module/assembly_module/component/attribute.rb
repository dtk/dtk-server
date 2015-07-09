module DTK; class AssemblyModule
  class Component
    class Attribute < self
      def self.update(assembly,cmp_level_attr_patterns)
        new(assembly).update(cmp_level_attr_patterns)
      end
      def update(cmp_level_attr_patterns)
        # TODO: more efficient to bulk up cmp_level_attr_patterns
        cmp_level_attr_patterns.map{|ap|update_aux(ap)}
      end

      private

      def update_aux(cmp_level_attr_pattern)
        cmp_instances = cmp_level_attr_pattern.component_instances()
        ndx_aug_cmp_templates = {}
        cmp_instances.each do |cmp|
          cmp_template = cmp.get_component_template_parent()
          pntr = ndx_aug_cmp_templates[cmp_template[:id]] ||= {component_template: cmp_template, component_instances: []}
          pntr[:component_instances] << cmp
        end
        unless ndx_aug_cmp_templates.size == 1
          raise Error.new('Not implemented yet when atttribute pattern is associated with more than one component template')
        end
        cmp_template = ndx_aug_cmp_templates.values.first[:component_template]

        component_module = cmp_template.get_component_module()
        module_branch = create_assembly_branch?(component_module,ret_module_branch: true)
        branch_cmp_template = get_branch_template(module_branch,cmp_template)
        cmp_level_attr_pattern.create_attribute_on_template(branch_cmp_template,update_dsl: {module_branch: module_branch})
      end
    end
  end
end;end
