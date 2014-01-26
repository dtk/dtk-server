module DTK; class ComponentDSL
  class RefIntegrity
    class ParsingError < ObjectModelForm::ParsingError
      class RefComponentTemplates < self
        def initialize(aug_cmp_templates)
          super(err_msg(aug_cmp_templates))
          @aug_cmp_templates = aug_cmp_templates
        end

       private
        def err_msg(aug_cmp_templates)
          msgs_per_cmp_template = msgs_per_cmp_template(aug_cmp_templates)
          ident = "    "
          ref_errors = ident + msgs_per_cmp_template.join("\n#{ident}")
          size = msgs_per_cmp_template.size
          what = (size==1 ? "component template" : "component templates")
          "The result if the changes were made would be the following #{what}\n  would be deleted while still being referenced by existing assembly templates:\n#{ref_errors}"
        end

        def msgs_per_cmp_template(aug_cmp_templates)
          assoc_component_assembly_templates(aug_cmp_templates).map do |cmp_tmpl,assem_array|
            assem_array.map do |assem|
              "Component Template (#{cmp_tmpl}) is referenced by assembly template (#{assem})"
            end
          end.flatten(1)
        end

        def assoc_component_assembly_templates(aug_cmp_templates)
          ret = Hash.new
          aug_cmp_templates.each do |cmp_tmpl|
            cmp_template = cmp_tmpl.display_name_print_form
            cmp_tmpl[:component_refs].map do |aug_cmp_ref|
              assembly_template = Assembly::Template.pretty_print_name(aug_cmp_ref[:assembly_template])
              assem_array = ret[cmp_template] ||= Array.new
              unless assem_array.include?(assembly_template)
                assem_array << assembly_template
              end
            end
          end
          ret
        end

      end
    end
  end
end; end

