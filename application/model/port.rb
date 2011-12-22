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
      return "east" if self[:display_name] =~ / ganglia__server/
      return "west" if self[:display_name] =~ / ganglia__monitor/
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
   public
    #TODO: assumption that ref and display_name are teh same
    def component_name()
      self[:display_name].split("___")[1]
    end
    def attribute_name()
      self[:display_name].split("___")[2]
    end
    def ref_num()
      self[:display_name].split("___")[3].to_i
    end
   private
    def self.port_ref(type,attr)
      ref_num = (attr[:component_ref_num]||1).to_s
      "#{type}___#{attr[:component_ref]}___#{attr[:display_name]}___#{ref_num}"
    end
    
    def self.strip_type(ref)
      ref.gsub(/^[^_]+___/,"")
    end

    def self.add_type(type,stripped_ref)
      "#{type}___#{stripped_ref}"
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
    def self.create_needed_component_ports(component_link_defs,node,component,opts={})
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

        ref = "#{type}___#{component_type}___#{link_def[:link_type]}"
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
   private
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
