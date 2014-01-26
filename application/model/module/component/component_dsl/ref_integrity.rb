module DTK
  class ComponentDSL
    class RefIntegrity
      r8_nested_require('ref_integrity','parsing_error')
      def self.snapshot_associated_assembly_templates(cmp_module)
        new(cmp_module)
      end

      def raise_error_if_any_violations(opts={})
        pp [:snapshot_cmp_refs,@snapshot_cmp_refs]
        pp [:snapshot_ports,@snapshot_ports]
        pp [:snapshot_port_links,@snapshot_port_links]
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
        @snapshot_cmp_refs = snapshot_cmp_refs(cmp_module)
        @snapshot_ports = snapshot_ports(@snapshot_cmp_refs)
        @snapshot_port_links = snapshot_port_links(@snapshot_ports)
      end

      #snapshot_cmp_refs is Ruby object that has form 
      # Component::Template:
      #   component_refs:
      #   - ComponentRef:
      #      node: Node
      #      assembly_template: Assembly::Template
      def snapshot_cmp_refs(cmp_module)
        cmp_module.get_associated_assembly_cmp_refs()
      end
      def snapshot_ports(snapshot_cmp_refs)
        ret = Array.new
        cmp_template_ids = @snapshot_cmp_refs.map{|ct|ct[:component_refs].map{|cr|cr[:component_template_id]}}.flatten.uniq
        if cmp_template_ids.empty?
          return ret
        end
        sp_hash = {
          :cols => [:id,:group_id,:ref,:display_name,:component_id],
          :filter => [:oneof,:component_id,cmp_template_ids]
        }
        Model.get_objs(model_handle(:port),sp_hash,:keep_ref_cols => true)
      end
      def snapshot_port_links(snapshot_ports)
        ret = Array.new
        if snapshot_ports.empty?
          return ret
        end
        port_ids = snapshot_ports.map{|p|p[:id]}
        sp_hash = {
          :cols => [:id,:group_id,:input_id,:output_id],
          :filter => [:or, [:oneof,:input_id,port_ids],[:oneof,:output_id,port_ids]]
        }
        Model.get_objs(model_handle(:port_link),sp_hash)
      end

      def raise_error_if_dangling_cmp_ref(opts={})
        return if @snapshot_cmp_refs.empty?
        #this is called within transaction after any deletes are performed (if any)
        #TODO: have ComponentDSL.parse_and_update_model return if any deletes
        #below is the conservative thing to do if dont know if any deletes
        any_deletes = true
        any_deletes = false if opts[:no_deletes_performed]
        return unless any_deletes
        
        sp_hash = {
          :cols => [:id,:display_name,:group_id],
          :filter => [:oneof, :id, @snapshot_cmp_refs.map{|r|r[:id]}]
        }
        cmp_template_ids_still_present = Model.get_objs(model_handle(:component),sp_hash).map{|r|r[:id]}
        referenced_cmp_templates = @snapshot_cmp_refs.reject{|r|cmp_template_ids_still_present.include?(r[:id])}
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
