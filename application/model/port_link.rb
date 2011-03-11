module XYZ
  class PortLink < Model
    def self.create(parent_idh,links_to_create)
      parent_mn =  parent_idh[:model_name]
      parent_id = parent_idh.get_id()
      port_link_mh = parent_idh.createMH(:model_name => :port_link,:parent_model_name => parent_mn)
      parent_col = DB.parent_field(parent_mn,:port_link)
      rows = links_to_create.map do |link|
        {:input_id => link[:input_id],
         :output_id => link[:output_id],
          parent_col => parent_id,
          :ref => "port_link:#{link[:input_id]}-#{link[:output_id]}"
        }
      end
      create_from_rows(port_link_mh,rows)
    end
  end
end
