module DTK
  class Node
    class Instance < Content
      def self.create_content_for_assembly_clone(node_idhs)
        sp_hash = {
          :cols => COMMON_REL_COLUMNS.keys + [:node_binding_rs_id,:content_instance_cmps_attrs],
          :filter => [:oneof,:id,node_idhs.map{|idh|idh.get_id()}]
        }
        sample_node_idh = node_idhs.first
        node_mh = sample_node_idh.createMH()
        content_rows = get_objs(node_mh,sp_hash,:keep_ref_cols => true)
        x = create(node_mh,content_rows.first)
        pp [x.class,x.id_handle,x]
      end
    end
  end
end
