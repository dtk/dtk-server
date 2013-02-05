module XYZ
  class Port < Model
    ####################
    def self.common_columns() 
      [
       :id,
       :display_name,
       :name,
       :description,
       :direction,
       :type,
       :location,
       :containing_port_id,
       :node_id
      ]
    end
    #virtual attribute defs
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
    
    def name()
      self[:display_name]
    end

    def node_id()
      self[:node_node_id]
    end
    
    ###########
    RefDelim = "___"
   public
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

    def self.ref_from_component_and_link_def_ref(type,component_type,link_def_ref,dir)
      "#{dir}#{RefDelim}#{type}#{RefDelim}#{component_type}#{RefDelim}#{link_def_ref}"
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

    #TODO: this can be avoided if we put more info in the port_link
    #aug_ports are ports augmented with :nested_component
    #removes nesetd_components not associated with teh port
    def self.add_link_defs_and_prune(aug_ports)
      ret = Array.new
      return ret if aug_ports.empty?
      #TODO: coud do this on db server side if it had field link_def_type
      filter_array = aug_ports.map do |port|
        link_type = port.parse_external_port_display_name()[:link_def_ref]
        port[:link_def_type] = link_type
        component =  port[:nested_component]
        [:and,[:eq,:component_component_id,component[:id]],[:eq,:link_type,link_type]]
      end
      sp_hash = {
        :cols => ([:component_component_id,:link_type]+LinkDef.common_columns()).uniq,
        :filter => [:or] + filter_array
      }
      link_def_mh = aug_ports.first.model_handle(:link_def)
      link_defs = get_objs(link_def_mh,sp_hash)
      
      aug_ports.each do |port|
        component = port[:nested_component]
        cmp_id = component[:id]
        if matching_ld = link_defs.find{|ld|ld[:link_type] == port[:link_def_type] and ld[:component_component_id] == cmp_id}
          ret << port.merge(:link_def => matching_ld)
        end
      end
      ret
    end

    def parse_external_port_display_name()
      display_name = get_field?(:display_name)
      self.class.parse_external_port_display_name(display_name)
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

    def self.set_ports_link_def_ids(port_mh,ports,cmps,link_defs)
      update_rows = ports.map do |port|
        parsed_port_name = parse_external_port_display_name(port[:display_name])
        cmp_type =  parsed_port_name[:component_type]
        link_def_ref = parsed_port_name[:link_def_ref]

        node_node_id = port[:node_node_id]
        #TODO: check display name will always be same as component_type
        unless cmp_match = cmps.find{|cmp|cmp[:display_name] == cmp_type and cmp[:node_node_id] == node_node_id}
          raise Error.new("Cannot find matching component for cloned port with id (#{port[:id].to_s})")
        end
        cmp_id = cmp_match[:id]
        unless link_def_match = link_defs.find{|ld|link_def_match?(ld,cmp_id,link_def_ref,parsed_port_name[:direction])}
          raise Error.new("Cannot find matching link def for component with id (#{cmp_id})")
        end
        {:id => port[:id], :link_def_id => link_def_match[:id]}
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

    #creates need component Ports and updates node_link_defs_info
    def self.create_component_ports?(component_link_defs,node,component,opts={})
      ret = Array.new
      return ret if component_link_defs.empty?

      node_id = node.id()
      port_mh = node.model_handle_with_auth_info.create_childMH(:port)
      component_type = (component.update_object!(:component_type))[:component_type]
      rows = component_link_defs.map do |link_def|
        type = 
          if link_def[:has_external_link]
            link_def[:has_internal_link] ? "component_internal_external" : "component_external"
          else #will be just link_def[:has_internal_link]
            "component_internal"
          end

        dir = direction_from_local_remote(link_def[:local_or_remote])
        ref = ref_from_component_and_link_def(type,component_type,link_def,dir)
        display_name = ref #TODO: rather than encoded name to component i18n name, make add a structured column likne name_context
        location_asserted = ret_location_asserted(component_type,link_def[:link_type])
        row = {
          :ref => ref,
          :display_name => display_name,
          :direction => dir,
          :link_def_id => link_def[:id],
          :node_node_id => node_id,
          :type => type
        }
        row[:location_asserted] = location_asserted if location_asserted
        row
      end
      create_from_rows(port_mh,rows,opts)
    end

    class << self
     private
      def direction_from_local_remote(local_or_remote)
        #TODO: just hueristc for computing dir; also need to upport "<>" (bidirectional)
        case local_or_remote 
          when "local" then "input" 
          when "remote" then "output"
        end
      end
    end

    #this function adds if necsssary ports onto nodes in assembly that correspond to link_defs_info
    #The link_defs_info is complete so any old ports not matches are removed
    def self.create_assembly_template_ports?(assembly,link_defs_info,opts={})
      ret = Array.new
      return ret if link_defs_info.empty?

      #make sure duplicate ports are pruned; tried to use :duplicate_refs => :prune_duplicates but bug; so explicitly looking fro existing ports
      sp_hash = {
        :cols => ([:node_node_id,:ref,:node] + (opts[:returning_sql_cols]||[])).uniq,
        :filter => [:oneof, :node_node_id, link_defs_info.map{|ld|ld[:node][:id]}]
      }

      port_mh = assembly.id_handle.create_childMH(:port)
      ndx_existing_ports = Hash.new
      Model.get_objs(port_mh,sp_hash,:keep_ref_cols => true).each do |r|
        (ndx_existing_ports[r[:node_node_id]] ||= Hash.new)[r[:ref]] = {:port => r,:matched => false}
      end 

      #Need to index by node because create_from_rows can only insert under one parent
      ndx_rows = Hash.new
      link_defs_info.each do |ld_info|
        link_def = ld_info[:link_def]
        cmp = ld_info[:nested_component]
        node = ld_info[:node]
        component_type = cmp[:component_type]
        type = 
          if link_def[:has_external_link]
            link_def[:has_internal_link] ? "component_internal_external" : "component_external"
          else #will be just ld_info[:has_internal_link]
            "component_internal"
          end

        dir = direction_from_local_remote(link_def[:local_or_remote])
        ref = ref_from_component_and_link_def(type,component_type,link_def,dir)
        if existing_port_info = (ndx_existing_ports[node[:id]]||{})[ref]
          existing_port_info[:matched] = true
          ret << existing_port_info[:port]
        else
          display_name = ref #TODO: rather than encoded name to component i18n name, make add a structured column likne name_context
          location_asserted = ret_location_asserted(component_type,link_def[:link_type])
          row = {
            :ref => ref,
            :display_name => display_name,
            :direction => dir,
            :link_def_id => link_def[:id],
            :node_node_id => node[:id],
            :type => type
          }
          row[:location_asserted] = location_asserted if location_asserted

          pntr = ndx_rows[node[:id]] ||= {:node => node, :create_rows => Array.new}
          pntr[:create_rows] << row
        end
      end

      new_rows = Array.new
      ndx_rows.values.each do |r|
        port_mh = r[:node].model_handle_with_auth_info.create_childMH(:port)
        new_rows += create_from_rows(port_mh,r[:create_rows],opts)
      end

      #delete any existing ports that match what is being put in now
      port_idhs_to_delete = Array.new
      ndx_existing_ports.each_value do |inner_ndx_ports|
        inner_ndx_ports.each_value do |port_info|
          unless port_info[:matched]
            port_idhs_to_delete << port_info[:port].id_handle()
          end
        end
      end
      unless port_idhs_to_delete.empty?()
        delete_instances(port_idhs_to_delete)
      end

      #for new rows need to splice in node info
      unless new_rows.empty?
        sp_hash = {
          :cols => [:id,:node],
          :filter => [:oneof, :node_node_id, new_rows.map{|p|p[:parent_id]}]
        }
        ndx_port_node = get_objs(port_mh,sp_hash).inject(Hash.new) do |h,r|
          h.merge(r[:id] => r[:node])
        end
        new_rows.each{|r|r.merge!(:node => ndx_port_node[r[:id]])}
      end
      ret + new_rows
    end

   private
    def self.ref_from_component_and_link_def(type,component_type,link_def,dir)
      ref_from_component_and_link_def_ref(type,component_type,link_def[:link_type],dir)
    end

    #TODO: this should be in link defs
    def self.ret_location_asserted(component_type,link_type)
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
  end
end
