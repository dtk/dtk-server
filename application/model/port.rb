module DTK
  class Port < Model
    ####################
    def self.common_columns() 
      [:id,:group_id,:display_name,:name,:description,:direction,:type,:location,:containing_port_id,:node_id]
    end

    def self.check_valid_id(model_handle,id,opts={}) 
      if opts[:assembly_idh]
        sp_hash = {
          :cols => [:id,:node],
          :filter => [:eq,:id,id]
        }
        rows = get_objs(model_handle,sp_hash)
        unless port = rows.first
          raise ErrorIdInvalid.new(id,pp_object_type())
        end
        unless port[:node][:assembly_id] == opts[:assembly_idh].get_id()
          Raise ErrorUsage.new("Port with id (#{id.to_s}) does not belong to assembly")
        end
        id
      else
        check_valid_id_default(model_handle,id)
      end
    end

    #name should be of form <node>/<component>, like server/rsyslog::server
    def self.name_to_id(model_handle,name,opts={})
      unless opts[:assembly_idh] and opts[:connection_type]
        raise Error.new("Unexpected options given in Port.name_to_id (#{opts.inspect}")
      end
      assembly_id = opts[:assembly_idh].get_id()
      conn_type = opts[:connection_type]
      node_display_name,poss_port_display_names = Port.parse_to_ret_display_name(name,conn_type,opts)
      unless node_display_name
        raise ErrorUsage.new("Port name (#{name}) is ill-formed")
      end
      augmented_sp_hash = {
        :cols => [:id,:node],
        :filter => [:oneof,:display_name,poss_port_display_names],
        :post_filter => lambda{|r|r[:node][:assembly_id] == assembly_id and r[:node][:display_name] == node_display_name}
      }
      name_to_id_helper(model_handle,name,augmented_sp_hash)
    end

    #virtual attribute defs    
    def name()
      self[:display_name]
    end

    def node_id()
      self[:node_node_id]
    end
    
    ###########
    RefDelim = "___"

    #this is an augmented port that has keys: node and optionally :link_def
    def display_name_print_form()
      info = parse_external_port_display_name()
      cmp_ref = ((info[:module] == info[:component]) ? info[:component] : "#{info[:module]}::#{info[:component]}")
      node = self[:node]
      "#{node[:display_name]}/#{cmp_ref}"
    end

    #this is an augmented port that has keys: node and optionally :link_def
    def print_form_hash()
      ret = {
        :id => self[:id],
        :type => link_def_name,
        :service_ref => display_name_print_form()
      }
      if link_def = self[:link_def] 
        ret.merge!(link_def.hash_subset(:required,:description))
      end
      ret
    end

    #TODO: assumption that ref and display_name are the same
    def component_name()
      self.class.parse_external_port_display_name(self[:display_name])[:component_type]
    end
    def link_def_name()
      self.class.parse_external_port_display_name(self[:display_name])[:link_def_ref]
    end

    #TODO: is this still used and right?
    def ref_num()
      self[:display_name].split(RefDelim)[3].to_i
    end

    def parse_external_port_display_name()
      display_name = get_field?(:display_name)
      self.class.parse_external_port_display_name(display_name)
    end
    def set_port_info!()
      self[:port_info] ||= parse_external_port_display_name()
    end
    def self.parse_external_port_display_name(port_display_name)
      ret = Hash.new
      #example internal form ([output|input]___)component_external___hdp-hadoop__namenode___namenode_conn
      #TODO: deprecate fotms with out input or output
      if port_display_name =~ Regexp.new("^input#{RefDelim}(.+$)")
        port_display_name = $1
        ret.merge!(:direction => :input)
      elsif port_display_name =~ Regexp.new("^output#{RefDelim}(.+$)")
        port_display_name = $1
        ret.merge!(:direction => :output)
      end

      if port_display_name =~ Regexp.new("component_external#{RefDelim}(.+)__(.+)#{RefDelim}(.+$)")
        ret.merge(:module => $1,:component => $2,:link_def_ref => $3,:component_type => "#{$1}__#{$2}")
      elsif  port_display_name =~ Regexp.new("component_external#{RefDelim}(.+)#{RefDelim}(.+$)")
        ret.merge(:module => $1,:component => $1,:link_def_ref => $2,:component_type => $1)
      else
        raise Error.new("unexpected display name (#{port_display_name})")
      end
    end
    
    #this function maps from service ref to internal display name
    #node_display_name,poss_port_display_names
    #input is of form form <node>/<component>, like server/rsyslog::server
    #if error, returns nil
    def self.parse_to_ret_display_name(service_ref_name,conn_type,opts={})
      if service_ref_name =~ Regexp.new("(^[^/]+)/([^/]+$)")
        node_display_name = $1
        cmp_ref = $2
        cmp_ref_internal_form = cmp_ref.gsub(/::/,"__")
        dirs = (opts[:direction] ? [options[:direction]] : ["input","output"])
        int_or_ext = opts[:internal_or_external]
        int_or_ext =  (int_or_ext ? [int_or_ext] : ["internal","external"])
        poss_p_names = dirs.map do |dir|
          int_or_ext.map do |ie|
            "#{dir}#{RefDelim}component_#{ie}#{RefDelim}#{cmp_ref_internal_form}#{RefDelim}#{conn_type}"
          end
        end.flatten
        [node_display_name,poss_p_names]
      end
    end

    def self.set_ports_link_def_ids(port_mh,ports,cmps,link_defs)
      update_rows = ports.map do |port|
        parsed_port_name = parse_external_port_display_name(port[:display_name])
        cmp_type =  parsed_port_name[:component_type]
        link_def_ref = parsed_port_name[:link_def_ref]

        node_node_id = port[:node_node_id]
        #TODO: check if need to match on version too or can only be one version type per component
        unless cmp_match = cmps.find{|cmp|cmp[:component_type] == cmp_type and cmp[:node_node_id] == node_node_id}
          raise Error.new("Cannot find matching component for cloned port with id (#{port[:id].to_s})")
        end
        cmp_id = cmp_match[:id]
        if link_def_match = link_defs.find{|ld|link_def_match?(ld,cmp_id,link_def_ref,parsed_port_name[:direction])}
          {:id => port[:id], :link_def_id => link_def_match[:id]}
        end
      end.compact
      update_from_rows(port_mh,update_rows)
    end

   private
    def self.link_def_match?(ld,cmp_id,link_def_ref,dir)
      if ld[:component_component_id] ==  cmp_id and
          ld[:display_name].gsub(/^remote_/,"").gsub(/^local_/,"") == link_def_ref
        if dir
          if ld[:display_name] =~ /^remote_/
            dir.to_s == direction_from_local_remote("remote")
          elsif ld[:display_name] =~ /^local_/
            dir.to_s == direction_from_local_remote("local")
          end
        else
          true
        end
      end
    end

    def self.port_ref(type,attr)
      ref_num = (attr[:component_ref_num]||1).to_s
      "#{type}#{RefDelim}#{attr[:component_ref]}#{RefDelim}#{attr[:display_name]}#{RefDelim}#{ref_num}"
    end
    
    def self.strip_type(ref)
      ref.gsub(Regexp.new("^[^_]+#{RefDelim}"),"")
    end

    def self.add_type(type,stripped_ref)
      "#{type}#{RefDelim}#{stripped_ref}"
    end
   public
    #returns nil if filtered
    def filter_and_process!(i18n,*types)
      unless types.empty?  
        return nil unless types.include?(self[:type])
        if types.include?("external") #TODO: this special case may go away
          return nil if self[:containing_port_id].nil? 
        end
      end

      merge!(:display_name => get_i18n_port_name(i18n,self)) if i18n
      merge!(:port_type=> self[:direction]) #TODO: should probably deprecate after get rid of using in front end
      materialize!(self.class.common_columns())
    end

    def self.get_attribute_info(port_id_handles)
      get_objects_in_set_from_sp_hash(port_id_handles,:columns => [:id,:attribute]).map do |r|
        {
          :id => r[:id],
          :attribute => r[:attribute_direct]||r[:attribute_nested]
        }
      end
    end

    #creates needed component Ports and updates node_link_defs_info
    def self.create_component_ports?(component_link_defs,node,component,opts={})
      ret = Array.new
      rows = component_link_defs.map{|link_def|ret_port_create_hash(link_def,node,component,opts)}
      return ret if rows.empty?
      port_mh = node.model_handle(:port)
      create_from_rows(port_mh,rows,opts)
    end

    def self.ret_port_create_hash(link_def,node,component,opts={})
      node_id = node.id()
      port_mh = node.model_handle_with_auth_info.create_childMH(:port)
      component_type = component.get_field?(:component_type)
      type = 
        if link_def[:has_external_link]
          link_def[:has_internal_link] ? "component_internal_external" : "component_external"
        else #will be just link_def[:has_internal_link]
          "component_internal"
        end
          
      dir = direction_from_local_remote(link_def[:local_or_remote],opts)
      ref = ref_from_component_and_link_def(type,component_type,link_def,dir)
      display_name = ref #TODO: rather than encoded name to component i18n name, make add a structured column likne name_context
      location_asserted = ret_location_asserted(component_type,link_def[:link_type])
      row = {
        :ref => ref,
        :display_name => display_name,
        :direction => dir,
        :node_node_id => node_id,
        :component_type => component_type,
        :link_type => link_def[:link_type],
        :type => type
      }
      row.merge!(:location_asserted => location_asserted) if location_asserted
      row.merge!(:link_def_id => link_def[:id]) unless opts[:remote_side]
      row
    end

    class << self
      private
      def direction_from_local_remote(local_or_remote,opts={})
        #TODO: just heuristc for computing dir; also need to upport "<>" (bidirectional)
        if opts[:remote_side]
          case local_or_remote 
            when "local" then "output" 
            when "remote" then "input"
          end
        else
          case local_or_remote 
            when "local" then "input" 
            when "remote" then "output"
          end
        end
      end

      #TODO: this should be in link defs
      def ret_location_asserted(component_type,link_type)
        (LocationMapping[component_type.to_sym]||{})[link_type.to_sym]
      end
      LocationMapping = {
        :mysql__master => {
          :master_connection => "east"
        },
        :mysql__slave => {
          :master_connection => "west"
        }
      }
      
      def ref_from_component_and_link_def(type,component_type,link_def,dir)
        ref_from_component_and_link_def_ref(type,component_type,link_def[:link_type],dir)
      end

      def ref_from_component_and_link_def_ref(type,component_type,link_def_ref,dir)
        "#{dir}#{RefDelim}#{type}#{RefDelim}#{component_type}#{RefDelim}#{link_def_ref}"
      end
    end

    #virtual attribute defs
    #related to UX direction
    def location()
      return self[:location_asserted] if self[:location_asserted]
      #TODO: stub
      return "east" if self[:display_name] =~ /nagios__server/
      return "east" if self[:display_name] =~ /mysql__master/
      return "west" if self[:display_name] =~ /nagios__client/
      return "east" if self[:display_name] =~ /ganglia server/
      return "west" if self[:display_name] =~ /ganglia monitor/

      case self[:direction]
        when "output" then "north"
        when "input" then "south"
      end
    end

  end
end
