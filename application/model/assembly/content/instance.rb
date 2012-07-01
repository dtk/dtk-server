module DTK
  class Assembly
    class Instance < Content
      def self.create_content(model_handle)
        content_rows = get_objs(model_handle,:cols => [:content_instance_nodes_cmps_attrs])
        pp content_rows
      end
    end
  end
end
