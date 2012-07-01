module DTK
  class Assembly
    class Instance < Content
      def self.create_content(assembly_idh)
        sp_hash = {
          :cols => [:id,:display_name,:content_instance_nodes_cmps_attrs],
          :filter => [:eq,:id,assembly_idh.get_id()]
        }
        mh = assembly_idh.createMH()
        content_rows = get_objs(mh,sp_hash,:keep_ref_cols => true)
        
        x = create(mh,content_rows.first)
        pp [x.class,x.id_handle,x]
      end
    end
  end
end
