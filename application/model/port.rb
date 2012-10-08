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
    #TODO: assumption that ref and display_name are the same
    def component_name()
      self[:display_name].split(RefDelim)[1]
    end
    def attribute_name()
      self[:display_name].split(RefDelim)[2]
    end
    def ref_num()
      self[:display_name].split(RefDelim)[3].to_i
    end

    def self.parse_external_port_display_name(port_display_name)
      #example internal form component_external___hdp-hadoop__namenode___namenode_conn
      if port_display_name =~ Regexp.new("component_external#{RefDelim}(.+)__(.+)#{RefDelim}(.+$)")
        {:module => $1,:component => $2,:link_def_ref => $3,:component_type => "#{$1}__#{$2}"}
      elsif  port_display_name =~ Regexp.new("component_external#{RefDelim}(.+)#{RefDelim}(.+$)")
        {:module => $1,:component => $1,:link_def_ref => $2,:component_type => $1}
      else
        raise Error.new("unexpected display name (#{port_display_name})")
      end
    end

   private
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

        ref = ref_from_component_and_link_def(type,component_type,link_def)
        display_name = ref #TODO: rather than encoded name to component i18n name, make add a structured column likne name_context
        #TODO: just hueristc for computing dir; also need to upport "<>" (bidirectional)
        dir = link_def[:local_or_remote] == "local" ?  "input" : "output"
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
        (ndx_existing_ports[r[:node_node_id]] ||= Hash.new)[r[:ref]] = r
      end 

      #TODO: need to index by node because create_from_rows can only insert under one parent; if this is changed can do one insert for all
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

        ref = ref_from_component_and_link_def(type,component_type,link_def)
        if existing = (ndx_existing_ports[node[:id]]||{})[ref]
          ret << existing
        else
          display_name = ref #TODO: rather than encoded name to component i18n name, make add a structured column likne name_context
          #TODO: just heuristc for computing dir; also need to upport "<>" (bidirectional)
          dir = link_def[:local_or_remote] == "local" ?  "input" : "output"
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

    def self.ref_from_component_and_link_def_ref(type,component_type,link_def_ref)
      "#{type}#{RefDelim}#{component_type}#{RefDelim}#{link_def_ref}"
    end
   private
    def self.ref_from_component_and_link_def(type,component_type,link_def)
      ref_from_component_and_link_def_ref(type,component_type,link_def[:link_type])
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
