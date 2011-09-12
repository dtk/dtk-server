module XYZ
  class PortLink < Model
    def self.create_from_links_hash(parent_idh,links_to_create)
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

    def self.create_port_and_attr_links(parent_idh,port_link_hash,opts={})
      #get the associated link_def_link TODO: if it does not exist means contraint violation
      link_def_link = get_associated_link_def_link(parent_idh,port_link_hash)
#TODO: incrementally putting back in
=begin
      #make sure that there is a possible link that corresponds to the drawn port link
      attr_mh = parent_idh.createMH(:model_name => :attribute,:parent_model_name=>:component) #TODO: parent model name can also be node
      attr_info = get_attribute_info(attr_mh,port_link_hash)
      set_external_link_info!(port_link_hash,attr_info)
      get_context!(port_link_hash,attr_info)
      check_constraints(attr_mh,port_link_hash)
      create_attr_links_aux!(port_link_hash,parent_idh,attr_mh,attr_info,opts)
      process_external_link_defs?(parent_idh,port_link_hash,attr_info)

      #TODO: assumption is that what is created by process_external_link_defs? has no bearing on l4 ports (as manifsted by using attr_links arg computred before process_external_link_defs? call
      attr_links = port_link_hash.map{|r|{:input => attr_info[r[:input_id]],:output => attr_info[r[:output_id]]}}
      Port.create_and_update_l4_ports_and_links?(parent_idh,attr_links)
=end
    end

    def self.get_associated_link_def_link(parent_idh,port_link_hash)
      sp_hash = {
        :cols => [:link_def_info],
        :filter => [:oneof, :id, [port_link_hash[:input_id],port_link_hash[:output_id]]]
      }
      link_def_info = get_objs(parent_idh.createMH(:port),sp_hash)
      link_def_info
    end
  end
end
