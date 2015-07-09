module DTK
  class ModuleDSL
    class ParsingError
      class RefComponentTemplates < self
        def initialize(ref_cmp_templates)
          super(err_msg(ref_cmp_templates))
          @ref_cmp_templates = ref_cmp_templates
        end

        private

        def err_msg(ref_cmp_templates)
          msgs_per_cmp_template = msgs_per_cmp_template(ref_cmp_templates)
          ident = '    '
          ref_errors = ident + msgs_per_cmp_template.join("\n#{ident}")
          size = msgs_per_cmp_template.size
          what = (size==1 ? 'component template' : 'component templates')
          "The result if the changes were made would be the following #{what}\n  would be deleted while still being referenced by existing assembly templates:\n#{ref_errors}"
        end

        def msgs_per_cmp_template(ref_cmp_templates)
          ref_cmp_templates.flat_map do |ref_cmp_template|
            cmp_tmpl_name = ref_cmp_template[:component_template].display_name_print_form
            assembly_templates = ref_cmp_template[:assembly_templates]
            Assembly::Template.augment_with_namespaces!(assembly_templates)
            assembly_templates.map do |assembly_template|
              assembly_template_name = Assembly::Template.pretty_print_name(assembly_template,include_namespace: true)
              "Component Template (#{cmp_tmpl_name}) is referenced by assembly template (#{assembly_template_name})"
            end
          end
        end
      end
    end
  end
end
