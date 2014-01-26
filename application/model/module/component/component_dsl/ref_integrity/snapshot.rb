module DTK; class ComponentDSL
  class RefIntegrity
    class Snapshot
      def initialize(cmp_module)
        @cmp_module_mh = cmp_module.model_handle()
        #ndx_cmp_refs is component refs indexed by component template; plus augmented info for cmp refs; it has form
        # Component::Template:
        #   component_refs:
        #   - ComponentRef:
        #      node: Node
        #      assembly_template: Assembly::Template
        @ndx_cmp_refs = get_ndx_cmp_refs(cmp_module)
        @ports = get_ports(@ndx_cmp_refs)
        @port_links = get_port_links(@ports)

        pp [:snapshot_ndx_cmp_refs,@ndx_cmp_refs]
        pp [:snapshot_ports,@ports]
        pp [:snapshot_port_links,@port_links]
      end

      def cmp_ref_ids()
        @ndx_cmp_refs.map{|r|r[:id]}
      end

      def referenced_cmp_templates(exclude_cmp_template_ids)
        pruned_ndx_cmp_refs = @ndx_cmp_refs.reject{|ct|exclude_cmp_template_ids.include?(ct[:id])}
        pp [:ref_cmp_templates,ReferencedComponentTemplates.new(pruned_ndx_cmp_refs)]
        #TODO: temp until pass ref_cmp_templates
        pruned_ndx_cmp_refs
      end

     private
      def get_ndx_cmp_refs(cmp_module)
        cmp_module.get_associated_assembly_cmp_refs()
      end
      def get_ports(ndx_cmp_refs)
        ret = Array.new
        cmp_template_ids = ndx_cmp_refs.map{|ct|ct[:component_refs].map{|cr|cr[:component_template_id]}}.flatten.uniq
        if cmp_template_ids.empty?
          return ret
        end
        sp_hash = {
          :cols => [:id,:group_id,:ref,:display_name,:component_id],
          :filter => [:oneof,:component_id,cmp_template_ids]
        }
        Model.get_objs(model_handle(:port),sp_hash,:keep_ref_cols => true)
      end
      def get_port_links(ports)
        ret = Array.new
        if ports.empty?
          return ret
        end
        port_ids = ports.map{|p|p[:id]}
        sp_hash = {
          :cols => [:id,:group_id,:input_id,:output_id],
          :filter => [:or, [:oneof,:input_id,port_ids],[:oneof,:output_id,port_ids]]
        }
        Model.get_objs(model_handle(:port_link),sp_hash)
      end

      def model_handle(model_name)
        @cmp_module_mh.createMH(model_name)
      end

      class ReferencedComponentTemplates < Array
        def initialize(ndx_cmp_refs)
          super(ref_cmp_templates(ndx_cmp_refs))
        end
       private
        def ref_cmp_templates(ndx_cmp_refs)
          ndx_ret = Hash.new
          ndx_cmp_refs.each do |cmp_tmpl|
            ndx = cmp_tmpl[:id]
            cmp_tmpl[:component_refs].map do |aug_cmp_ref|
              pntr = ndx_ret[ndx] ||= {:component_ref => aug_cmp_ref.hash_subset(*CmpRefCols), :assembly_templates => Array.new}
              existing_assembly_templates = pntr[:assembly_templates]
              assembly_template = aug_cmp_ref[:assembly_template]
              assembly_template_id = assembly_template[:id]
              unless existing_assembly_templates.find{|assem|assem[:id] == assembly_template_id}
                existing_assembly_templates<< assembly_template
              end
            end
          end
          ndx_ret.values
        end
        CmpRefCols = [:id,:display_name,:group_id,:component_type,:version=,:module_branch_id]
      end
    end
  end
end; end

