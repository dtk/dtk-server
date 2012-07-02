module DTK
  class Assembly
    class Instance < Content
      def self.create_container_for_clone(library_idh,assembly_name,service_module_name,module_branch,icon_info)
        hash_values = {
          :library_library_id => library_idh.get_id(),
          :ref => "#{service_module_name}-#{assembly_name}",
          :display_name => assembly_name,
          :ui => icon_info,
          :type => "composite",
          :module_branch_id => module_branch[:id]
        }
        assembly_mh = library_idh.create_childMH(:component)
        ret = create(assembly_mh,hash_values)
        pp [ret.class,ret.id_handle,ret]
        ret
      end
      def add_content_for_clone(node_idhs,link_idhs)
        sp_hash = {
          :cols => COMMON_REL_COLUMNS.keys + [:node_binding_rs_id,:cmps_and_non_default_attrs],
          :filter => [:oneof,:id,node_idhs.map{|idh|idh.get_id()}]
        }
        sample_node_idh = node_idhs.first
        node_mh = sample_node_idh.createMH()
        content_rows = Model.get_objs(node_mh,sp_hash,:keep_ref_cols => true)
        pp content_rows
      end
    end
  end
end
