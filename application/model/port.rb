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
    #returns nil if filtered
    def filter_and_process!(type=nil,i18n=nil)
      keep = 
        (type.nil? or 
          case type
            when "external" then self[:type] == "external"
            #if type is l4 return l4 ports and external ones not yet placed under a l4 port
            when "l4" then self[:type] == "l4" or (self[:type] == "external" and self[:containing_port_id].nil?)
          end)
      return nil unless keep
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

    def self.create_component_external_ports?(node_idh,component_idh)
      ret = Array.new
      sp_hash = {
        :cols => [:link_type, :local_or_remote],
        :filter => [:and, [:eq, :component_component_id, component_idh.get_id()],
                    [:eq, :has_external_link, true]]
      }
      link_defs = get_objs(node_idh.createMH(:link_def),sp_hash)
      return ret if link_defs.empty?
      #only create if doesnt exist
      node_id = node_idh.get_id()
      sp_hash = {
        :cols => [:tag],
        :filter => [:and, [:eq, :node_node_id, node_id],
                    [:eq, :type, "component_external"]]
      }
      port_mh = node_idh.create_childMH(:port)
      existing_ports = get_objs(port_mh,sp_hash)
      unless existing_ports.empty?
        existing_tags = existing_ports.map{|r|r[:tag]}
        link_defs.reject!{|r|existing_tags.include?(r[:link_type])}
        return ret if link_defs.empty?
      end
      
      rows = link_defs.map do |ld|
        ref = ld[:link_type] #TODO: may make this component_name-link_type
        #TODO: just hueristc for computing dir; also need to upport "<>" (bidirectional)
        dir = ld[:local_or_remote] == "local" ?  "input" : "output"
        {
          :ref => ref,
          :direction => dir,
          :node_node_id => node_id,
          :type => "component_external",
          :tag => ld[:link_type]
        }
      end
      create_from_rows(port_mh,rows)
    end

    #TODO: deprecate for above
    def self.create_ports_for_external_attributes(node_idh,component_idh)
      component = component_idh.create_object()
      attrs_external = component.get_attributes_ports().select do |attr|
        attr[:port_is_external] and attr[:has_port_object]
      end
      return if attrs_external.empty?
      node_id = node_idh.get_id()

      new_ports = attrs_external.map do |attr|
        type = attr[:port_type] == "output" ? "l4" : "external"
        ref = port_ref(type,attr)
        hash = {
          :type => type,
          :ref => ref,
          :display_name => ref,
          :node_node_id => node_id,
          :direction => attr[:port_type]
        }
        hash.merge!(:location_asserted => attr[:port_location]) if attr[:port_location]
        hash.merge(attr[:port_type] == "input" ? {:external_attribute_id => attr[:id]} : {})
      end
      port_mh = node_idh.createMH(:model_name => :port, :parent_model_name => :node)
      opts = {:returning_sql_cols => [:ref,:id]}
      create_info = create_from_rows(port_mh,new_ports,opts)

      #for output ports need to nest in l4 ports
      output_attrs = attrs_external.select{|a|a[:port_type] == "output"}
      return if output_attrs.empty?
      new_port_index = create_info.inject({}){|h,ret_info|h.merge(strip_type(ret_info[:ref]) => ret_info[:id])}

      nested_ports = output_attrs.map do |attr|
        type = "external"
        ref = port_ref(type,attr)
        {
          :type => type,
          :ref => ref,
          :display_name => ref,
          :external_attribute_id => attr[:id],
          :node_node_id => node_id,
          :containing_port_id => new_port_index[strip_type(ref)],
          :direction => "output"
        }
      end
      create_from_rows(port_mh,nested_ports)
    end

    def self.create_and_update_l4_ports_and_links?(parent_idh,attr_links)
      ret = {:new_port_links => Array.new,:new_l4_ports => Array.new, :merged_external_ports => Array.new}
      return ret if attr_links.empty?
      sample_attr = attr_links.first[:input]
      node_mh = sample_attr.model_handle.createMH(:node)


      #compute indexed_input_ports (indexed by port) and indexed_input_external_ports (indexed by attr)
      input_node_idhs = attr_links.inject({}) do |h,attr_link|
        node_id = attr_link[:input][:component_parent][:node_node_id]
        h.merge(node_id => node_mh.createIDH(:id => node_id))
      end.values
      input_ports = Node.get_ports(input_node_idhs)
      indexed_input_ports = input_ports.inject({}){|h,port|h.merge(port[:id] => port)}
      indexed_input_external_ports = input_ports.inject({}) do |h,port|
        index = port[:external_attribute_id]
        index ? h.merge(index => port) : h
      end

      output_node_idhs = attr_links.inject({}) do |h,attr_link|
        node_id = attr_link[:output][:component_parent][:node_node_id]
        h.merge(node_id => node_mh.createIDH(:id => node_id))
      end.values
      output_attr_to_l4_input_port = Node.get_output_attrs_to_l4_input_ports(output_node_idhs)

      #for each input in attr_links either it must be placed under an existing l4 port or a layer 4 port must be created for it
      #matching criteria is that external input goes under an existing l4 port if 
      #1) there is another external port on node that has output that maps to same output
      #2) the internal port is alreadfy associated with a l4 port
     input_attr_to_l4 = Hash.new
      indexed_l4_input_to_create = Hash.new
      attr_links.each do |attr_link|
        #compute matching_l4_port and state (whether l4 and or link exists) , if it exists
        matching_l4_port = state = nil
        input_attr = attr_link[:input]
        input_id = input_attr[:id]
        input_external_port = indexed_input_external_ports[input_id]
        input_node_id = input_attr[:component_parent][:node_node_id]
        output_id = attr_link[:output][:id]

        if matching_l4_port = (output_attr_to_l4_input_port[output_id]||[]).find{|p|p[:node_node_id] == input_node_id}
          state = :l4_link_exists
        elsif matching_l4_port = indexed_input_ports[input_external_port[:containing_port_id]]
          state = :l4_port_exists
        end

        if matching_l4_port
          input_attr_to_l4[input_id] ||= {:port_id => matching_l4_port[:id], :state => state} 
        else
          indexed_l4_input_to_create[input_id] ||= input_attr.merge(:port => input_external_port)
        end
      end
      l4_input_to_create = indexed_l4_input_to_create.values

      #create needed l4 ports and update input_attr_to_l4
      l4_idhs = create_l4_input_ports(l4_input_to_create)
      ret[:new_l4_ports] = l4_idhs.map{|idh|idh.get_id()}
      l4_input_to_create.each_with_index do |attr,i|
        input_attr_to_l4[attr[:id]] = {:port_id => l4_idhs[i].get_id(), :state =>  :created}
      end

      #create needed l4 port_links
      attr_links_for_port_links = attr_links.reject{|l|input_attr_to_l4[l[:input][:id]][:state] == :l4_link_exists}
      unless attr_links_for_port_links.empty?
        output_attr_idhs = attr_links_for_port_links.map{|link_info|link_info[:output].id_handle}.uniq
        output_attr_to_l4 = Attribute.get_port_info(output_attr_idhs).inject({}) do |h,port_info|
          h.merge(port_info[:port_external][:external_attribute_id] => port_info[:port_l4][:id])
        end

        l4_links_to_create = attr_links_for_port_links.map do |link_info|
          {:input_id => input_attr_to_l4[link_info[:input][:id]][:port_id],
            :output_id => output_attr_to_l4[link_info[:output][:id]]}
        end.uniq
        ret[:new_port_links] = PortLink.create_from_links_hash(parent_idh,l4_links_to_create).map{|idh|idh.get_id()}
      end

      #reroot neeeded external ports
      reroot_info = attr_links.map{|l|l[:input][:id]}.uniq.map do |attr_id|
        {
          :attribute_id => attr_id,
          :external_port_id => indexed_input_external_ports[attr_id][:id],
          :l4_port_id => input_attr_to_l4[attr_id][:port_id]
        }
      end
      ret[:merged_external_ports] = reroot_info.map{|r|Aux::hash_subset(r,[:external_port_id,:l4_port_id])}
      port_mh = parent_idh.createMH(:port)
      reroot_external_ports(port_mh,reroot_info)
      ret
    end
=begin
    def self.create_and_update_l4_ports_and_links?(parent_idh,link_info_list)
      ret = {:new_port_links => Array.new,:new_l4_ports => Array.new, :merged_external_ports => Array.new}
      return ret if link_info_list.empty?
      sample_attr = link_info_list.first[:input]
      node_mh = sample_attr.model_handle.createMH(:node)

      #compute indexed_input_external_ports
      input_node_idhs = link_info_list.inject({}) do |h,link_info|
        node_id = link_info[:input][:component_parent][:node_node_id]
        h.merge(node_id => node_mh.createIDH(:id => node_id))
      end.values
      indexed_input_external_ports = Node.get_ports(input_node_idhs).inject({}) do |h,port|
        index = port[:external_attribute_id]
        index ? h.merge(index => port) : h
      end

      output_node_idhs = link_info_list.inject({}) do |h,link_info|
        node_id = link_info[:output][:component_parent][:node_node_id]
        h.merge(node_id => node_mh.createIDH(:id => node_id))
      end.values
      attr_to_ports = Node.get_output_attrs_to_l4_input_ports(output_node_idhs)

      #for each input in link_info_list either it must be placed under an existing l4 port or a layer 4 port must be created for it
      #in all cases the input external port must be rerooted under the (existing or new l4 port)

      #compute input attribute to l4 output mapping
      input_attr_to_l4 = Hash.new
      l4_input_to_create = Array.new
      link_info_list.each do |link_info|
        add_to_l4_input_to_create = false
        output_id = link_info[:output][:id]
        input_attr = link_info[:input]
        unless ports = attr_to_ports[output_id]
          add_to_l4_input_to_create = true
        else
          input_node_id = input_attr[:component_parent][:node_node_id]
          unless port = ports.find{|p|p[:node_node_id] == input_node_id}
            add_to_l4_input_to_create = true
          else
            input_attr_to_l4[input_attr[:id]] = {:port_id => port[:id], :state => :existed} 
          end
        end
        if add_to_l4_input_to_create
          l4_input_to_create << input_attr.merge(:port => indexed_input_external_ports[input_attr[:id]])
        end
      end

      #create needed l4 ports and update input_attr_to_l4
      l4_idhs = create_l4_input_ports(l4_input_to_create)
      ret[:new_l4_ports] = l4_idhs.map{|idh|idh.get_id()}
      l4_input_to_create.each_with_index do |attr,i|
        input_attr_to_l4[attr[:id]] = {:port_id => l4_idhs[i].get_id(), :state =>  :created}
      end

      #create needed l4 port_links
      attr_links_for_port_links = link_info_list.select{|l|input_attr_to_l4[l[:input][:id]][:state] == :created}
      unless attr_links_for_port_links.empty?
        output_attr_idhs = attr_links_for_port_links.map{|link_info|link_info[:output].id_handle}.uniq
        output_attr_to_l4 = Attribute.get_port_info(output_attr_idhs).inject({}) do |h,port_info|
          h.merge(port_info[:port_external][:external_attribute_id] => port_info[:port_l4][:id])
        end

        l4_links_to_create = attr_links_for_port_links.map do |link_info|
          {:input_id => input_attr_to_l4[link_info[:input][:id]][:port_id],
            :output_id => output_attr_to_l4[link_info[:output][:id]]}
        end.uniq
        ret[:new_port_links] = PortLink.create_from_links_hash(parent_idh,l4_links_to_create).map{|idh|idh.get_id()}
      end

      #reroot neeeded external ports
      reroot_info = link_info_list.map{|l|l[:input][:id]}.uniq.map do |attr_id|
        {
          :attribute_id => attr_id,
          :external_port_id => indexed_input_external_ports[attr_id][:id],
          :l4_port_id => input_attr_to_l4[attr_id][:port_id]
        }
      end
      ret[:merged_external_ports] = reroot_info.map{|r|Aux::hash_subset(r,[:external_port_id,:l4_port_id])}
      port_mh = parent_idh.createMH(:port)
      reroot_external_ports(port_mh,reroot_info)
      ret
    end
=end  
   private
    def self.reroot_external_ports(port_mh,reroot_info)
      return if reroot_info.empty?
      update_rows = reroot_info.map do |info|
        {
          :id => info[:external_port_id],
          :containing_port_id => info[:l4_port_id],
         }
      end
       update_from_rows(port_mh,update_rows)
    end

    def self.create_l4_input_ports(attrs_external)
      return Array.new if attrs_external.empty?
      new_l4_ports = attrs_external.map do |attr|
        node_id = attr[:component_parent][:node_node_id]
        type = "l4"
        ref = add_type(type,strip_type(attr[:port][:ref]))
        {
          :type => type,
          :ref => ref,
          :display_name => ref,
          :node_node_id => node_id,
          :direction => "input"
        }
      end
      sample = attrs_external.first
      model_handle = sample.model_handle.createMH(:model_name => :port, :parent_model_name => :node)
      create_from_rows(model_handle,new_l4_ports)
    end
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
  end
end
