module DTK
  class LinkDef
    # Each element has form
    #   <Assemby::Template>
    #   id: ID
    #   node: NODE
    #   component_ref: ComponentRef
    #   nested_component: ComponentTemplate
    #   link_def:
    #     <LinkDef>
    #     link_def_links:
    #     - LinkDef::Link
    class Info < Array
      def self.component_ref_cols
        ComponentRef.common_cols()
      end
      def self.nested_component_cols
        [:id,:display_name,:component_type, :extended_base, :implementation_id, :node_node_id,:only_one_per_node]
      end

      def self.get_link_def_info(assembly_template)
        link_defs_info = new(assembly_template.get_objs(cols: [:template_link_defs_info]))
        link_defs_info.add_link_def_links!()
      end

      def add_link_def_links!
        link_defs = link_defs()
        return self if link_defs.empty?()
        sp_hash = {
          cols: [:id,:group_id,:link_def_id,:remote_component_type],
          filter: [:oneof, :link_def_id, link_defs.map{|ld|ld[:id]}]
        }
        link_def_link_mh = link_defs.first.model_handle(:link_def_link)
        ndx_link_def_links = Model.get_objs(link_def_link_mh,sp_hash).inject({}) do |h,r|
          h.merge(r[:link_def_id] => r)
        end

        link_defs.each do |link_def|
          if link = ndx_link_def_links[link_def[:id]]
            (link_def[:link_def_links] ||= []) << link
          end
        end
        self
      end

      # signature generate_link_def_link_pairs do |link_def,link|
      def generate_link_def_link_pairs(&body)
        ndx_ld_links_mark = {}
        link_defs().each do |link_def|
          ndx = link_def[:id]
          unless ndx_ld_links_mark[ndx]
            ndx_ld_links_mark[ndx] = true
            (link_def[:link_def_links]||{}).each{|link|body.call(link_def,link)}
          end
        end
      end

      def link_defs
        ret = []
        each do |ld_info|
          if link_def = ld_info[:link_def]
            ret << link_def
          end
        end
        ret
      end
    end
  end
end
