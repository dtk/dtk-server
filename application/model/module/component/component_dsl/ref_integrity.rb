module DTK
  class ComponentDSL
    class RefIntegrity
      r8_nested_require('ref_integrity','snapshot')
      r8_nested_require('ref_integrity','parsing_error')
      def self.snapshot_associated_assembly_templates(cmp_module)
        new(cmp_module)
      end

      def raise_error_if_any_violations(opts={})
        raise_error_if_dangling_cmp_ref(opts)
        raise_error_if_dangling_port_link()
        #TODO: other violations
      end

      def integrity_post_processing()
        add_new_ports_on_component_templates()
      end

     private
      def initialize(cmp_module)
        @cmp_module = cmp_module
        @snapshot = Snapshot.new(cmp_module)
      end

      def raise_error_if_dangling_cmp_ref(opts={})
        cmp_ref_ids = @snapshot.cmp_ref_ids()
        return if cmp_ref_ids.empty?
        #this is called within transaction after any deletes are performed (if any)
        #TODO: have ComponentDSL.parse_and_update_model return if any deletes
        #below is the conservative thing to do if dont know if any deletes
        any_deletes = true
        any_deletes = false if opts[:no_deletes_performed]
        return unless any_deletes
        
        sp_hash = {
          :cols => [:id,:display_name,:group_id],
          :filter => [:oneof, :id, cmp_ref_ids]
        }
        cmp_template_ids_still_present = Model.get_objs(model_handle(:component),sp_hash).map{|r|r[:id]}
        referenced_cmp_templates = @snapshot.referenced_cmp_templates(cmp_template_ids_still_present)
        unless referenced_cmp_templates.empty?
          raise ParsingError::RefComponentTemplates.new(referenced_cmp_templates)
        end
      end

      def raise_error_if_dangling_port_link()
        #TODO: stub
      end

      def add_new_ports_on_component_templates()
        #TODO: stub
      end

      def model_handle(model_name)
        @cmp_module.model_handle(model_name)
      end
    end
  end
end
