module DTK; class ModuleDSL
  class RefIntegrity
    class Snapshot
      attr_reader :link_defs
      def initialize(component_module)
        @component_module = component_module
        # aug_cmp_templates is array with component ref info augmented to it
        @aug_cmp_templates = get_aug_cmp_templates(component_module)
        @ports = get_ports(@aug_cmp_templates)
        @port_links = get_port_links(@ports)
        @link_defs = get_link_defs(@aug_cmp_templates)
      end

      def component_template_ids(aug_cmp_templates=nil)
        aug_cmp_templates ||= @aug_cmp_templates
        aug_cmp_templates.map{|cmp_template|cmp_template.id()}
      end

      def referenced_cmp_templates(exclude_cmp_template_ids)
        pruned_aug_cmp_templates = @aug_cmp_templates.reject{|ct|exclude_cmp_template_ids.include?(ct[:id])}
        ReferencedComponentTemplates.new(pruned_aug_cmp_templates)
      end

      def create_link_def_info(new_links_defs)
        link_def_info = LinkDef::Info.new
        
        # link defs indexed by component template
        ndx_link_defs = new_links_defs.inject({}) do |h,ld|
          h.merge(ld[:component_component_id] => ld)
        end
        
        @aug_cmp_templates.each do |cmp_template|
          if link_def = ndx_link_defs[cmp_template[:id]]
            cmp_template[:component_refs].each do |cmp_ref|
              node = cmp_ref[:node]
              assembly_template = cmp_ref[:assembly_template]
              el = assembly_template.merge(
                node: node,
                component_ref: cmp_ref.hash_subset(*LinkDef::Info.component_ref_cols()),
                nested_component: cmp_template.hash_subset(*LinkDef::Info.nested_component_cols()),
                link_def: link_def                                         
              )
              link_def_info << el
            end
          end
        end
        link_def_info.add_link_def_links!()
      end

      private

      # writing the get function sso can be passed explicitly refernce object or can use the internal @ vars
      def get_aug_cmp_templates(component_module=nil)
        component_module ||= @component_module
        component_module.get_associated_assembly_cmp_refs()
      end

      def get_link_defs(aug_cmp_templates=nil)
        aug_cmp_templates ||= @aug_cmp_templates
        ret = []
        cmp_template_ids = component_template_ids(aug_cmp_templates)
        if cmp_template_ids.empty?
          return ret
        end
        sp_hash = {
          cols: LinkDef.common_columns()+[:ref,:component_component_id],
          filter: [:oneof,:component_component_id,cmp_template_ids]
        }
        Model.get_objs(model_handle(:link_def),sp_hash,keep_ref_cols: true)
      end

      def get_ports(aug_cmp_templates=nil)
        aug_cmp_templates ||= @aug_cmp_templates
        ret = []
        cmp_template_ids = component_template_ids(aug_cmp_templates)
        if cmp_template_ids.empty?
          return ret
        end
        sp_hash = {
          cols: [:id,:group_id,:ref,:display_name,:component_id,:node_node_id,:node],
          filter: [:oneof,:component_id,cmp_template_ids]
        }
        Model.get_objs(model_handle(:port),sp_hash,keep_ref_cols: true)
      end

      def get_port_links(ports=nil)
        ports ||= @ports
        ret = []
        if ports.empty?
          return ret
        end
        port_ids = ports.map{|p|p[:id]}
        sp_hash = {
          cols: [:id,:group_id,:input_id,:output_id],
          filter: [:or, [:oneof,:input_id,port_ids],[:oneof,:output_id,port_ids]]
        }
        Model.get_objs(model_handle(:port_link),sp_hash)
      end

      def model_handle(model_name)
        @component_module.model_handle(model_name)
      end

      class ReferencedComponentTemplates < Array
        def initialize(aug_cmp_templates)
          super(ref_cmp_templates(aug_cmp_templates))
        end

        private

        def ref_cmp_templates(aug_cmp_templates)
          ret = []
          if aug_cmp_templates.empty?
            return ret
          end
          ndx_ret = {}
          aug_cmp_templates.each do |cmp_tmpl|
            ndx = cmp_tmpl[:id]
            cmp_tmpl[:component_refs].map do |aug_cmp_ref|
              pntr = ndx_ret[ndx] ||= {component_template: aug_cmp_ref.hash_subset(*CmpTemplateCols), assembly_templates: []}
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
        CmpTemplateCols = [:id,:display_name,:group_id,:component_type,:version=,:module_branch_id]
      end
    end
  end
end; end

