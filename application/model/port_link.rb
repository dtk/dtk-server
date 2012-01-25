module XYZ
  class PortLink < Model
    def self.common_columns()
      [:id,:input_id,:output_id]
    end

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
      create_opts = {:returning_sql_cols => [:id,:input_id,:output_id]}
      #TODO: push in use of :c into create_from_rows
      create_from_rows(port_link_mh,rows,create_opts).map{|hash|new(hash,port_link_mh[:c])}
    end

    #called when adding a node under a node group
    def self.create_attr_links_from_port_link(parent_idh,port_link)
      opts = {:port_link_created_already => true, :no_create_events => true}
      create_port_and_attr_links(parent_idh,port_link,opts)
    end

    def self.create_port_and_attr_links(parent_idh,port_link_hash,opts={})
      #get the associated link_def_link TODO: if it does not exist means constraint violation
      link_def_link, components = get_link_def_and_components(parent_idh,port_link_hash)
      raise PortLinkError.new("Illegal link") unless link_def_link
      port_link = (opts[:port_link_created_already] ? port_link_hash : create_from_links_hash(parent_idh,[port_link_hash]).first)
      link_def_link.process(parent_idh,components,opts.merge(:port_link_id => port_link.id_handle))
      port_link
    end

    def self.get_link_def_and_components(parent_idh,port_link_hash)
      #returns [link_def_link,relevant_components]
      ret = [nil,nil]
      sp_hash = {
        :cols => [:link_def_info],
        :filter => [:oneof, :id, [port_link_hash[:input_id],port_link_hash[:output_id]]]
      }
      link_def_info = get_objs(parent_idh.createMH(:port),sp_hash)
      #local_cmp_info wil haev a row per link_def_link associated with it (link_def_link under local link defs, not remote ones)
      local_cmp_info_and_links = link_def_info.select{|r|r[:link_def][:local_or_remote] == "local"}
      return ret if local_cmp_info_and_links.empty?
      local_cmp_info = local_cmp_info_and_links.first #all elements wil agree on the parts aside from link_def_link

      remote_cmp_info = link_def_info.find{|r|r[:link_def][:local_or_remote] == "remote"}
      return ret unless remote_cmp_info
      return ret unless local_cmp_info[:link_def][:link_type] == remote_cmp_info[:link_def][:link_type]
      #find the matching link_def_link
      remote_cmp_type = remote_cmp_info[:component][:component_type]
      match = local_cmp_info_and_links.find{|r|(r[:link_def_link]||{})[:remote_component_type] == remote_cmp_type} 
      return ret unless match
      link_def_link = match[:link_def_link].merge!(:local_component_type => local_cmp_info[:component][:component_type])
      relevant_components = [local_cmp_info[:component], remote_cmp_info[:component]]
      [link_def_link,relevant_components]
    end
  end

  class PortLinkError < ErrorForUser
  end
end
