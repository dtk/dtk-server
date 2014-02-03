module DTK; class ComponentDSL
  class RefIntegrity
    class Snapshot
#TODO: for testing
attr_reader :ndx_cmp_refs,:ports,:port_links
      attr_reader :link_defs
      def initialize(cmp_module)
        @cmp_module = cmp_module
        #ndx_cmp_refs is component refs indexed by component template; plus augmented info for cmp refs; it has form
        # Component::Template:
        #   component_refs:
        #   - ComponentRef:
        #      node: Node
        #      assembly_template: Assembly::Template
        @ndx_cmp_refs = get_ndx_cmp_refs(cmp_module)
        @ports = get_ports(@ndx_cmp_refs)
        @port_links = get_port_links(@ports)
        @link_defs = get_link_defs(@ndx_cmp_refs)
      end

      def cmp_ref_ids()
        @ndx_cmp_refs.map{|r|r[:id]}
      end

      def referenced_cmp_templates(exclude_cmp_template_ids)
        pruned_ndx_cmp_refs = @ndx_cmp_refs.reject{|ct|exclude_cmp_template_ids.include?(ct[:id])}
        ReferencedComponentTemplates.new(pruned_ndx_cmp_refs)
      end

      def create_link_def_info(new_links_defs)
        link_def_info = LinkDef::Info.new
        
        #link defs indexed by component template
        ndx_link_defs = new_links_defs.inject(Hash.new) do |h,ld|
          h.merge(ld[:component_component_id] => ld)
        end
        
        @ndx_cmp_refs.each do |cmp_template|
          if link_def = ndx_link_defs[cmp_template[:id]]
            cmp_template[:component_refs].each do |cmp_ref|
              node = cmp_ref[:node]
              assembly_template = cmp_ref[:assembly_template]
              el = assembly_template.merge(
                :node => node,
                :component_ref => cmp_ref.hash_subset(*LinkDef::Info.component_ref_cols()),
                :nested_component => cmp_template.hash_subset(*LinkDef::Info.nested_component_cols()),
                :link_def => link_def                                         
              )
              link_def_info << el
            end
          end
        end
        link_def_info.add_link_def_links!()
      end

     private
      #writing the get function sso can be passed explicitly refernce object or can use the internal @ vars
      def get_ndx_cmp_refs(cmp_module=nil)
        cmp_module ||= @cmp_module
        cmp_module.get_associated_assembly_cmp_refs()
      end
      def get_link_defs(ndx_cmp_refs=nil)
        ndx_cmp_refs ||= @ndx_cmp_refs
        ret = Array.new
        cmp_template_ids = cmp_template_ids(ndx_cmp_refs)
        if cmp_template_ids.empty?
          return ret
        end
        sp_hash = {
          :cols => LinkDef.common_columns()+[:ref,:component_component_id],
          :filter => [:oneof,:component_component_id,cmp_template_ids]
        }
        Model.get_objs(model_handle(:link_def),sp_hash,:keep_ref_cols => true)
      end
      def get_ports(ndx_cmp_refs=nil)
        ndx_cmp_refs ||= @ndx_cmp_refs
        ret = Array.new
        cmp_template_ids = cmp_template_ids(ndx_cmp_refs)
        if cmp_template_ids.empty?
          return ret
        end
        sp_hash = {
          :cols => [:id,:group_id,:ref,:display_name,:component_id,:node_node_id,:node],
          :filter => [:oneof,:component_id,cmp_template_ids]
        }
        Model.get_objs(model_handle(:port),sp_hash,:keep_ref_cols => true)
      end
      def get_port_links(ports=nil)
        ports ||= @ports
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

      def cmp_template_ids(ndx_cmp_refs=nil)
        ndx_cmp_refs ||= @ndx_cmp_refs
        ndx_cmp_refs.map{|ct|ct[:component_refs].map{|cr|cr[:component_template_id]}}.flatten.uniq
      end

      def model_handle(model_name)
        @cmp_module.model_handle(model_name)
      end

      class ReferencedComponentTemplates < Array
        def initialize(ndx_cmp_refs)
          super(ref_cmp_templates(ndx_cmp_refs))
        end
       private
        def ref_cmp_templates(ndx_cmp_refs)
          ret = Array.new
          if ndx_cmp_refs.empty?
            return ret
          end
          ndx_ret = Hash.new
          ndx_cmp_refs.each do |cmp_tmpl|
            ndx = cmp_tmpl[:id]
            cmp_tmpl[:component_refs].map do |aug_cmp_ref|
              pntr = ndx_ret[ndx] ||= {:component_template => aug_cmp_ref.hash_subset(*CmpTemplateCols), :assembly_templates => Array.new}
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

