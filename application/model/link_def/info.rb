module DTK
  class LinkDef
    #Each element has form
    #   <Assemby::Template>
    #   id: ID
    #   node: NODE 
    #   component_ref: ComponentRef
    #   nested_component: ComponentTemplate
    #   link_def: 
    #     <LinkDef> 
    #     link_def_links:
    #     - LinkDefLink 
    class Info < Array
      def self.component_ref_cols()
        ComponentRef.common_cols()        
      end
      def self.nested_component_cols()
        [:id,:display_name,:component_type, :extended_base, :implementation_id, :node_node_id,:only_one_per_node]
      end

      def self.get_link_def_info(assembly_template)
        link_defs_info = new(assembly_template.get_objs(:cols => [:template_link_defs_info]))
        return link_defs_info if link_defs_info.empty?
        
        sp_hash = {
          :cols => [:id,:group_id,:link_def_id,:remote_component_type],
          :filter => [:oneof, :link_def_id, link_defs_info.map{|r|(r[:link_def]||{})[:id]}.compact]
        }
        rows = Model.get_objs(assembly_template.model_handle(:link_def_link),sp_hash)
        ndx_link_def_links = rows.inject(Hash.new){|h,r|h.merge(r[:link_def_id] => r)}
        link_defs_info.each do |r|
          if link_def = r[:link_def]
            if link = ndx_link_def_links[link_def[:id]]
              (link_def[:link_def_links] ||= Array.new) << link
            end
          end
        end
        link_defs_info
      end

      #should be called as generate_link_def_link_pairs do |link_def,link|
      def generate_link_def_link_pairs(&body)
        ndx_ld_links_mark = Hash.new
        each do |ld_info|
          if link_def = ld_info[:link_def]
            ndx = link_def[:id]
            next if ndx_ld_links_mark[ndx]
            ndx_ld_links_mark[ndx] = true
            (link_def[:link_def_links]||{}).each{|link|body.call(link_def,link)} 
          end
        end
      end

    end
  end
end
    
