module DTK
  class Assembly
    class Instance < Content
      def self.create_content(model_handle)
        content_rows = get_objs(model_handle,:cols => [:content_instance_nodes_cmps_attrs])
        x = create(model_handle,content_rows.first)
        pp [x.class,x.id_handle,x]
      end
    end
  end
end
