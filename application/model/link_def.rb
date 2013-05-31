module DTK
  class LinkDef < Model
    r8_nested_require('link_def','auto_complete')
    r8_nested_require('link_def','parse_serialized_form')
    extend ParseSerializedFormClassMixin

    def self.common_columns()
      [:id,:group_id,:display_name,:description,:local_or_remote,:link_type,:required,:dangling,:has_external_link,:has_internal_link]
    end

    def self.get_link_def_links(link_def_idhs,opts={})
      ret = Array.new
      return ret if link_def_idhs.empty?
      sp_hash = {
        :cols => opts[:cols]||LinkDefLink.common_columns(),
        :filter => [:oneof,:link_def_id,link_def_idhs.map{|idh|idh.get_id()}]
      }
      ld_link_mh = link_def_idhs.first.create_childMH(:link_def_link)
      get_objs(ld_link_mh,sp_hash)
    end

    #ports are augmented with link def under :link_def key
    def self.find_possible_connections(unconnected_aug_ports,output_aug_ports)
      ret = Array.new
      output_aug_ports.each{|r|r.set_port_info!()}
      set_link_def_links!(unconnected_aug_ports)
      opts = {:port_info_is_set=>true,:link_def_links_are_set=>true}
      unconnected_aug_ports.each do |unc_port|
        ret += unc_port[:link_def].find_possible_connection(unc_port,output_aug_ports,opts)
      end
      ret
    end
    #unc_aug_port and output_aug_ports have keys :node
    def find_possible_connection(unc_aug_port,output_aug_ports,opts={})
      ret = Array.new
      unless opts[:port_info_is_set]
        output_aug_ports.each{|r|r.set_port_info!()}
      end
      unless opts[:link_def_links_are_set]
        LinkDef.set_link_def_links!(unc_aug_port)
      end

      unc_aug_port.set_port_info!()
      (unc_aug_port[:link_def][:link_def_links]||[]).each do |ld_link|
        matches = ld_link.ret_matches(unc_aug_port,output_aug_ports)
        ret += matches
      end
      ret
    end

    def self.set_link_def_links!(aug_ports)
      aug_ports = [aug_ports] unless aug_ports.kind_of?(Array)
      ndx_link_defs = aug_ports.inject(Hash.new) do |h,r|
        ld = r[:link_def]
        h.merge(ld[:id] => ld)
      end
      ld_link_cols = [:id,:group_id,:display_name,:type,:position,:remote_component_type,:link_def_id] 
      ld_links = get_link_def_links(ndx_link_defs.values.map{|r|r.id_handle()},:cols => ld_link_cols)
      ld_links.each do |r|
        (ndx_link_defs[r[:link_def_id]][:link_def_links] ||= Array.new) << r
      end
      nil
    end

  end
end

