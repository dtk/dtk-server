module DTK
  class ComponentDSL
    class RefIntegrity
      r8_nested_require('ref_integrity','parsing_error')

      def self.snapshot_associated_assembly_templates(cmp_module)
        new(cmp_module)
      end

      def raise_error_if_any_violations(opts={})
        raise_error_if_dangling_cmp_ref(opts)
        #TODO: other violations
      end

      def integrity_post_processing()
        #TODO: step that will refresh if needed assoc assembly templates; such as refreshing so ports associated with new link defs and components are created
      end

     private
      def initialize(cmp_module)
        @cmp_module = cmp_module
        @assoc_cmp_refs = cmp_module.get_associated_assembly_cmp_refs()
        pp [:assoc_cmp_refs,@assoc_cmp_refs]

        #TODO: also want to get info about ports on assoc templates and port links
      end

      def raise_error_if_dangling_cmp_ref(opts={})
        return if @assoc_cmp_refs.empty?
        #this is called within transaction after any deletes are performed (if any)
        #TODO: have ComponentDSL.parse_and_update_model return if any deletes
        #below is the conservative thing to do if dont know if any deletes
        any_deletes = true
        if opts[:no_deletes_performed]
          any_deletes = false
        end
        return unless any_deletes
        
        sp_hash = {
          :cols => [:id,:display_name,:group_id],
          :filter => [:oneof, :id, @assoc_cmp_refs.map{|r|r[:id]}]
        }
        cmp_template_ids_still_present = Model.get_objs(model_handle(:component),sp_hash).map{|r|r[:id]}
        referenced_cmp_templates = @assoc_cmp_refs.reject{|r|cmp_template_ids_still_present.include?(r[:id])}
        unless referenced_cmp_templates.empty?
          raise ParsingError::RefComponentTemplates.new(referenced_cmp_templates)
        end
      end

      def model_handle(model_name)
        @cmp_module.model_handle(model_name)
      end

    end
  end
end
