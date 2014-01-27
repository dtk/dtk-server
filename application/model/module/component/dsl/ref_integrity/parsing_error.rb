module DTK; class ComponentDSL
  class RefIntegrity
    class ParsingError < ObjectModelForm::ParsingError
      class RefComponentTemplates < self
        def initialize(ref_cmp_templates)
          super(err_msg(ref_cmp_templates))
          @ref_cmp_templates = ref_cmp_templates
        end

       private
        def err_msg(ref_cmp_templates)
          msgs_per_cmp_template = msgs_per_cmp_template(ref_cmp_templates)
          ident = "    "
          ref_errors = ident + msgs_per_cmp_template.join("\n#{ident}")
          size = msgs_per_cmp_template.size
          what = (size==1 ? "component template" : "component templates")
          "The result if the changes were made would be the following #{what}\n  would be deleted while still being referenced by existing assembly templates:\n#{ref_errors}"
        end

        def msgs_per_cmp_template(ref_cmp_templates)
          ref_cmp_templates.map do |ref_cmp_template|
            cmp_tmpl_name = ref_cmp_template[:component_template].display_name_print_form
            ref_cmp_template[:assembly_templates].map do |assembly_template|
              assembly_template_name = Assembly::Template.pretty_print_name(assembly_template)
              "Component Template (#{cmp_tmpl_name}) is referenced by assembly template (#{assembly_template_name})"
            end
          end.flatten(1)
        end
      end

    end
  end
end; end

