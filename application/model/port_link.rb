module XYZ
  class PortLink < Model
    def self.common_columns()
      [:id,:group_id,:input_id,:output_id]
    end

    #method name is somewhat of misnomer since with :donot_create_port_link, port links are not created
    def self.create_port_and_attr_links(parent_idh,port_link_hash,opts={})
      #get the associated link_def_link TODO: if it does not exist means constraint violation
      link_def_link, components = get_link_def_and_components(parent_idh,port_link_hash)
      raise PortLinkError.new("Illegal link") unless link_def_link
      if opts[:donot_create_port_link]
        port_link = port_link_hash 
        unless port_link_idh = opts[:port_link_idh]
          raise Error.new("if option :donot_create_port_link give, option :port_link_idh must be set")
        end
      else
        port_link = create_from_links_hash(parent_idh,[port_link_hash],opts).first
        port_link_idh = port_link.id_handle
      end
      link_def_link.process(parent_idh,components,opts.merge(:port_link_idh => port_link_idh))
      port_link
    end

    #expects augmented port link with keys :input_port, :output_port, :input_node, and :output_node
    def print_form_hash()
      input_port = print_form_hash__port(self[:input_port],self[:input_node])
      output_port = print_form_hash__port(self[:output_port],self[:output_node])
      link_def_name = self[:input_port].link_def_name()
      if link_def_name != self[:output_port].link_def_name()
        Log.error("input and output link defs are not equal")
      end
      #TODO: confiusing that input/output on port link does not reflect what is logical input/output
      if self[:input_port][:direction] == "input"
        left_hand_side = input_port
        right_hand_side = output_port
      else
        left_hand_side = output_port
        right_hand_side = input_port
      end

      {
        :id => self[:id],
        :type => link_def_name,
        :connection => "#{left_hand_side} <--> #{right_hand_side}"
      }
    end
    def print_form_hash__port(port,node)
      port.merge(:node=>node).display_name_print_form()
    end
    private :print_form_hash__port

    def self.create_from_links_hash(parent_idh,links_to_create,opts={})
      parent_mn =  parent_idh[:model_name]
      parent_id = parent_idh.get_id()
      port_link_mh = parent_idh.createMH(:model_name => :port_link,:parent_model_name => parent_mn)
      parent_col = DB.parent_field(parent_mn,:port_link)
      override_attrs = opts[:override_attrs]||{}
      rows = links_to_create.map do |link|
        {:input_id => link[:input_id],
         :output_id => link[:output_id],
          parent_col => parent_id,
          :ref => ref_from_ids(link[:input_id],link[:output_id])
        }.merge(override_attrs)
      end
      create_opts = {:returning_sql_cols => [:id,:input_id,:output_id]}
      #TODO: push in use of :c into create_from_rows
      create_from_rows(port_link_mh,rows,create_opts).map{|hash|new(hash,port_link_mh[:c])}
    end

    #TODO: think need to change to use locgical rdns instaed of ids to support a more efficient service/pull_from_remote so can determine diffs
    def self.ref_from_ids(input_id,output_id)
      "port_link:#{input_id}-#{output_id}"
    end

    def create_attr_links(parent_idh,opts={})
      update_object!(:input_id,:output_id)
      augmented_opts = opts.merge(:port_link_idh => id_handle,:donot_create_port_link => true)
      PortLink.create_port_and_attr_links(parent_idh,self,augmented_opts)
    end
   private
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

  class PortLinkError < ErrorUsage
  end
end
