module DTK
  class ComponentModule
    class RefIintegrity
      #this is called within transaction after any deletes are performed (if any)
      def self.raise_error?(cmp_module,aug_cmp_templates,opts={})
        new(cmp_module,aug_cmp_templates).raise_error?(opts)
      end

      def raise_error?(opts={})
        raise_error_if_dangling_cmp_ref(opts)
      end

     private
      def initialize(cmp_module,aug_cmp_templates)
        @cmp_module = cmp_module
        @aug_cmp_templates = aug_cmp_templates
      end

      def raise_error_if_dangling_cmp_ref(opts={})
        return if @aug_cmp_templates.empty?

        #TODO: have ComponentDSL.parse_and_update_model return if any deletes
        #below is the conservative thing to do if dont know if any deletes
        any_deletes = true
        if opts[:no_deletes_performed]
          any_deletes = false
        end
        return unless any_deletes
        
        sp_hash = {
          :cols => [:id,:display_name,:group_id],
          :filter => [:oneof, :id, @aug_cmp_templates.map{|r|r[:id]}]
        }
        cmp_template_ids_still_present = Model.get_objs(model_handle(:component),sp_hash).map{|r|r[:id]}
        referenced_cmp_templates = @aug_cmp_templates.reject{|r|cmp_template_ids_still_present.include?(r[:id])}
        unless referenced_cmp_templates.empty?
          raise ErrorUsage::ReferencedComponentTemplates.new(referenced_cmp_templates)
        end
      end

      def model_handle(model_name)
        @cmp_module.model_handle(model_name)
      end

    end
  end
end
